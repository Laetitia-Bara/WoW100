import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/models/tracking_category.dart';
import '../../data/models/tracking_item.dart';
import '../../data/models/wow_region_filter.dart';

enum RouteStepKind { portal, flight, go, hearthstone, objective }

enum RouteResetScope { none, daily, weekly }

class RouteTarget {
  const RouteTarget({
    required this.item,
    required this.nodeId,
    required this.nodeLabel,
    required this.zoneLabel,
  });

  final TrackingItem item;
  final String nodeId;
  final String nodeLabel;
  final String zoneLabel;
}

class PlannedRouteStep {
  const PlannedRouteStep({
    required this.id,
    required this.kind,
    required this.label,
    this.details = '',
    this.item,
    this.tags = const [],
    this.resetScope = RouteResetScope.none,
  });

  final String id;
  final RouteStepKind kind;
  final String label;
  final String details;
  final TrackingItem? item;
  final List<String> tags;
  final RouteResetScope resetScope;
}

class RoutePlan {
  const RoutePlan({
    required this.startNodeId,
    required this.startLabel,
    required this.steps,
    required this.targets,
  });

  final String startNodeId;
  final String startLabel;
  final List<PlannedRouteStep> steps;
  final List<RouteTarget> targets;
}

class RoutePlannerService {
  static const _assetPath = 'assets/data/routes/travel_graph.json';

  _TravelGraph? _cachedGraph;

  Future<RoutePlan> buildPlan({
    required List<TrackingItem> items,
    required String faction,
  }) async {
    final graph = await _loadGraph();
    final normalizedFaction = WowRegionFilter.normalize(faction);
    final capitalNode = normalizedFaction == 'alliance'
        ? 'stormwind'
        : 'orgrimmar';
    final capitalLabel = graph.nodeLabel(capitalNode);
    final targets = [
      for (final item in items) _targetForItem(item, graph, capitalNode),
    ];
    final remaining = [...targets];
    final steps = <PlannedRouteStep>[];
    var currentNode = capitalNode;

    while (remaining.isNotEmpty) {
      remaining.sort((left, right) {
        final leftPath = graph.shortestPath(
          currentNode,
          left.nodeId,
          normalizedFaction,
        );
        final rightPath = graph.shortestPath(
          currentNode,
          right.nodeId,
          normalizedFaction,
        );
        final costCompare = leftPath.cost.compareTo(rightPath.cost);
        if (costCompare != 0) return costCompare;

        final zoneCompare = left.zoneLabel.compareTo(right.zoneLabel);
        if (zoneCompare != 0) return zoneCompare;

        return left.item.name.compareTo(right.item.name);
      });

      final target = remaining.removeAt(0);
      final path = graph.shortestPath(
        currentNode,
        target.nodeId,
        normalizedFaction,
      );

      if (path.edges.isEmpty && currentNode != target.nodeId) {
        steps.add(
          PlannedRouteStep(
            id: 'go:$currentNode:${target.nodeId}:${target.item.id}',
            kind: RouteStepKind.go,
            label:
                'Go : ${graph.nodeLabel(currentNode)} -> ${target.nodeLabel}',
            details: 'Trajet manuel, aucun transport reference pour le moment.',
          ),
        );
      } else {
        for (final edge in path.edges) {
          steps.add(
            PlannedRouteStep(
              id: '${edge.type}:${edge.from}:${edge.to}:${target.item.id}',
              kind: edge.kind,
              label: edge.label,
            ),
          );
        }
      }

      final goLabel = _goLabel(target.item, target.zoneLabel);
      if (goLabel.isNotEmpty) {
        steps.add(
          PlannedRouteStep(
            id: 'go:${target.item.id}',
            kind: RouteStepKind.go,
            label: goLabel,
            details: _locationDetails(target.item),
          ),
        );
      }

      steps.add(
        PlannedRouteStep(
          id: 'objective:${target.item.id}',
          kind: RouteStepKind.objective,
          label: _objectiveLabel(target.item),
          details: _objectiveDetails(target.item),
          item: target.item,
          tags: _objectiveTags(target.item),
          resetScope: _resetScopeFor(target.item),
        ),
      );

      currentNode = target.nodeId;
    }

    return RoutePlan(
      startNodeId: capitalNode,
      startLabel: capitalLabel,
      steps: steps,
      targets: targets,
    );
  }

  Future<_TravelGraph> _loadGraph() async {
    final cachedGraph = _cachedGraph;
    if (cachedGraph != null) return cachedGraph;

    final jsonString = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final graph = _TravelGraph.fromJson(data);
    _cachedGraph = graph;

    return graph;
  }

  RouteTarget _targetForItem(
    TrackingItem item,
    _TravelGraph graph,
    String fallbackNodeId,
  ) {
    final nodeId = graph.nodeIdForItem(item, fallbackNodeId);
    final zoneLabel = _bestZoneLabel(item);

    return RouteTarget(
      item: item,
      nodeId: nodeId,
      nodeLabel: graph.nodeLabel(nodeId),
      zoneLabel: zoneLabel,
    );
  }

  String _bestZoneLabel(TrackingItem item) {
    for (final value in [item.subzone, item.zone, item.region, item.world]) {
      final trimmed = value.trim();
      if (_hasUsefulLabel(trimmed)) return trimmed;
    }

    return TrackingItem.unknownZone;
  }

  String _goLabel(TrackingItem item, String zoneLabel) {
    final destination = _routeDestinationLabel(item, zoneLabel);

    if (!_hasUsefulLabel(destination)) return '';

    return 'Go : aller a $destination';
  }

  String _objectiveLabel(TrackingItem item) {
    final action = switch (item.category) {
      TrackingCategory.achievements => 'Valider',
      TrackingCategory.mounts => 'Run',
      TrackingCategory.pets => 'Farmer',
      _ => 'Faire',
    };
    final contentTypeLabel = _contentTypeLabel(item);
    final destination = [
      ?contentTypeLabel,
      if (contentTypeLabel == null) _nonGenericLabel(item.instance),
      item.boss,
      item.source,
    ].where(_hasUsefulLabel).toList();

    if (destination.isEmpty) return '$action : ${item.name}';

    return '$action : ${destination.take(2).join(' - ')}';
  }

  String _objectiveDetails(TrackingItem item) {
    final parts = <String>[
      'Objectif : ${item.name}',
      item.category.shortLabel,
      if (item.frequencyLabel.trim().isNotEmpty)
        item.frequencyLabel.trim()
      else if (item.weeklyLockout)
        'Hebdomadaire',
    ];

    return parts.join(' - ');
  }

  List<String> _objectiveTags(TrackingItem item) {
    return [?_contentTypeLabel(item)];
  }

  String _routeDestinationLabel(TrackingItem item, String zoneLabel) {
    final hasInstanceContentType = _contentTypeLabel(item) != null;
    final candidates = hasInstanceContentType
        ? [
            item.subzone,
            item.zone,
            zoneLabel,
            _nonGenericLabel(item.instance),
            item.region,
          ]
        : [
            item.subzone,
            _nonGenericLabel(item.instance),
            item.zone,
            zoneLabel,
            item.region,
          ];

    for (final candidate in candidates) {
      final trimmed = candidate.trim();
      if (_hasUsefulLabel(trimmed)) return trimmed;
    }

    return '';
  }

  String? _contentTypeLabel(TrackingItem item) {
    final labels = [...item.tags, item.instance, item.source];

    for (final label in labels) {
      final normalized = WowRegionFilter.normalize(label);

      if (normalized == 'donjon' || normalized == 'dungeon') {
        return 'Donjon';
      }
      if (normalized == 'raid') {
        return 'Raid';
      }
    }

    return null;
  }

  String _nonGenericLabel(String value) {
    final trimmed = value.trim();
    final normalized = WowRegionFilter.normalize(trimmed);

    if (_genericSourceLabels.contains(normalized)) return '';

    return trimmed;
  }

  String _locationDetails(TrackingItem item) {
    final values = [item.world, item.region, item.zone, item.subzone];
    final uniqueValues = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final trimmed = value.trim();
      if (!_hasUsefulLabel(trimmed)) continue;

      final normalized = WowRegionFilter.normalize(trimmed);
      if (normalized.isEmpty || !seen.add(normalized)) continue;

      uniqueValues.add(trimmed);
    }

    if (uniqueValues.isEmpty) return '';

    return 'Zone : ${uniqueValues.join(' > ')}';
  }

  RouteResetScope _resetScopeFor(TrackingItem item) {
    final frequency = WowRegionFilter.normalize(item.frequencyLabel);
    final tags = item.tags.map(WowRegionFilter.normalize).join(' ');

    if (item.weeklyLockout ||
        frequency.contains('hebdo') ||
        frequency.contains('weekly') ||
        tags.contains('raid')) {
      return RouteResetScope.weekly;
    }

    if (frequency.contains('quotidien') ||
        frequency.contains('daily') ||
        frequency.contains('jour')) {
      return RouteResetScope.daily;
    }

    return RouteResetScope.none;
  }

  bool _hasUsefulLabel(String value) {
    final normalized = WowRegionFilter.normalize(value);

    return normalized.isNotEmpty &&
        normalized != WowRegionFilter.normalize(TrackingItem.unknownZone) &&
        normalized != 'unknown' &&
        normalized != 'a definir' &&
        normalized != 'a verifier' &&
        normalized != 'source a verifier';
  }

  static const Set<String> _genericSourceLabels = {
    'butin',
    'drop',
    'drops',
    'loot',
    'vendeur',
    'vendor',
    'quete',
    'quetes',
    'haut fait',
    'hauts faits',
    'reputation',
    'evenement mondial',
    'evenements mondiaux',
    'divers',
    'secret',
    'inconnu',
  };
}

class _TravelGraph {
  const _TravelGraph({
    required this.nodes,
    required this.locationNodes,
    required this.edges,
  });

  final Map<String, String> nodes;
  final Map<String, String> locationNodes;
  final List<_TravelEdge> edges;

  factory _TravelGraph.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? const [];
    final rawLocationNodes =
        json['locationNodes'] as Map<String, dynamic>? ?? const {};
    final rawEdges = json['edges'] as List<dynamic>? ?? const [];

    return _TravelGraph(
      nodes: {
        for (final node in rawNodes.whereType<Map<String, dynamic>>())
          if (_string(node['id']).isNotEmpty)
            _string(node['id']): _string(node['label']),
      },
      locationNodes: {
        for (final entry in rawLocationNodes.entries)
          if (_string(entry.value).isNotEmpty)
            WowRegionFilter.normalize(entry.key): _string(entry.value),
      },
      edges: [
        for (final edge in rawEdges.whereType<Map<String, dynamic>>())
          _TravelEdge.fromJson(edge),
      ],
    );
  }

  String nodeLabel(String nodeId) => nodes[nodeId] ?? nodeId;

  String nodeIdForItem(TrackingItem item, String fallbackNodeId) {
    for (final candidate in [
      item.locationRef,
      item.subzone,
      item.zone,
      item.region,
      item.world,
    ]) {
      final nodeId = locationNodes[WowRegionFilter.normalize(candidate)];
      if (nodeId != null && nodeId.isNotEmpty) return nodeId;
    }

    return fallbackNodeId;
  }

  _RoutePath shortestPath(String from, String to, String faction) {
    if (from == to) return const _RoutePath(cost: 0, edges: []);

    final distances = <String, double>{
      for (final nodeId in nodes.keys) nodeId: double.infinity,
    };
    final previousEdges = <String, _TravelEdge>{};
    final unvisited = nodes.keys.toSet();

    distances[from] = 0;

    while (unvisited.isNotEmpty) {
      final current = unvisited.reduce((left, right) {
        return distances[left]! <= distances[right]! ? left : right;
      });
      final currentDistance = distances[current]!;

      if (currentDistance == double.infinity || current == to) break;

      unvisited.remove(current);

      for (final edge in edges.where((edge) => edge.from == current)) {
        if (!edge.supportsFaction(faction) || !unvisited.contains(edge.to)) {
          continue;
        }

        final candidateDistance = currentDistance + edge.cost;
        if (candidateDistance < distances[edge.to]!) {
          distances[edge.to] = candidateDistance;
          previousEdges[edge.to] = edge;
        }
      }
    }

    final totalCost = distances[to] ?? double.infinity;
    if (totalCost == double.infinity) {
      return const _RoutePath(cost: 9999, edges: []);
    }

    final pathEdges = <_TravelEdge>[];
    var cursor = to;

    while (cursor != from) {
      final edge = previousEdges[cursor];
      if (edge == null) return const _RoutePath(cost: 9999, edges: []);

      pathEdges.insert(0, edge);
      cursor = edge.from;
    }

    return _RoutePath(cost: totalCost, edges: pathEdges);
  }

  static String _string(dynamic value) {
    return value is String ? value.trim() : '';
  }
}

class _TravelEdge {
  const _TravelEdge({
    required this.from,
    required this.to,
    required this.type,
    required this.label,
    required this.cost,
    required this.faction,
  });

  final String from;
  final String to;
  final String type;
  final String label;
  final double cost;
  final String faction;

  RouteStepKind get kind {
    return switch (type) {
      'portal' => RouteStepKind.portal,
      'flight' => RouteStepKind.flight,
      'hearthstone' => RouteStepKind.hearthstone,
      _ => RouteStepKind.go,
    };
  }

  factory _TravelEdge.fromJson(Map<String, dynamic> json) {
    return _TravelEdge(
      from: _TravelGraph._string(json['from']),
      to: _TravelGraph._string(json['to']),
      type: _TravelGraph._string(json['type']),
      label: _TravelGraph._string(json['label']),
      cost: (json['cost'] as num?)?.toDouble() ?? 1,
      faction: WowRegionFilter.normalize(_TravelGraph._string(json['faction'])),
    );
  }

  bool supportsFaction(String characterFaction) {
    return faction == 'both' || faction.isEmpty || faction == characterFaction;
  }
}

class _RoutePath {
  const _RoutePath({required this.cost, required this.edges});

  final double cost;
  final List<_TravelEdge> edges;
}
