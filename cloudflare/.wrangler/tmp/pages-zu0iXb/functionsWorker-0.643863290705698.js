var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/_internal/utils.mjs
// @__NO_SIDE_EFFECTS__
function createNotImplementedError(name) {
  return new Error(`[unenv] ${name} is not implemented yet!`);
}
__name(createNotImplementedError, "createNotImplementedError");
// @__NO_SIDE_EFFECTS__
function notImplemented(name) {
  const fn = /* @__PURE__ */ __name(() => {
    throw /* @__PURE__ */ createNotImplementedError(name);
  }, "fn");
  return Object.assign(fn, { __unenv__: true });
}
__name(notImplemented, "notImplemented");
// @__NO_SIDE_EFFECTS__
function notImplementedClass(name) {
  return class {
    __unenv__ = true;
    constructor() {
      throw new Error(`[unenv] ${name} is not implemented yet!`);
    }
  };
}
__name(notImplementedClass, "notImplementedClass");

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/perf_hooks/performance.mjs
var _timeOrigin = globalThis.performance?.timeOrigin ?? Date.now();
var _performanceNow = globalThis.performance?.now ? globalThis.performance.now.bind(globalThis.performance) : () => Date.now() - _timeOrigin;
var nodeTiming = {
  name: "node",
  entryType: "node",
  startTime: 0,
  duration: 0,
  nodeStart: 0,
  v8Start: 0,
  bootstrapComplete: 0,
  environment: 0,
  loopStart: 0,
  loopExit: 0,
  idleTime: 0,
  uvMetricsInfo: {
    loopCount: 0,
    events: 0,
    eventsWaiting: 0
  },
  detail: void 0,
  toJSON() {
    return this;
  }
};
var PerformanceEntry = class {
  static {
    __name(this, "PerformanceEntry");
  }
  __unenv__ = true;
  detail;
  entryType = "event";
  name;
  startTime;
  constructor(name, options) {
    this.name = name;
    this.startTime = options?.startTime || _performanceNow();
    this.detail = options?.detail;
  }
  get duration() {
    return _performanceNow() - this.startTime;
  }
  toJSON() {
    return {
      name: this.name,
      entryType: this.entryType,
      startTime: this.startTime,
      duration: this.duration,
      detail: this.detail
    };
  }
};
var PerformanceMark = class PerformanceMark2 extends PerformanceEntry {
  static {
    __name(this, "PerformanceMark");
  }
  entryType = "mark";
  constructor() {
    super(...arguments);
  }
  get duration() {
    return 0;
  }
};
var PerformanceMeasure = class extends PerformanceEntry {
  static {
    __name(this, "PerformanceMeasure");
  }
  entryType = "measure";
};
var PerformanceResourceTiming = class extends PerformanceEntry {
  static {
    __name(this, "PerformanceResourceTiming");
  }
  entryType = "resource";
  serverTiming = [];
  connectEnd = 0;
  connectStart = 0;
  decodedBodySize = 0;
  domainLookupEnd = 0;
  domainLookupStart = 0;
  encodedBodySize = 0;
  fetchStart = 0;
  initiatorType = "";
  name = "";
  nextHopProtocol = "";
  redirectEnd = 0;
  redirectStart = 0;
  requestStart = 0;
  responseEnd = 0;
  responseStart = 0;
  secureConnectionStart = 0;
  startTime = 0;
  transferSize = 0;
  workerStart = 0;
  responseStatus = 0;
};
var PerformanceObserverEntryList = class {
  static {
    __name(this, "PerformanceObserverEntryList");
  }
  __unenv__ = true;
  getEntries() {
    return [];
  }
  getEntriesByName(_name, _type) {
    return [];
  }
  getEntriesByType(type) {
    return [];
  }
};
var Performance = class {
  static {
    __name(this, "Performance");
  }
  __unenv__ = true;
  timeOrigin = _timeOrigin;
  eventCounts = /* @__PURE__ */ new Map();
  _entries = [];
  _resourceTimingBufferSize = 0;
  navigation = void 0;
  timing = void 0;
  timerify(_fn, _options) {
    throw createNotImplementedError("Performance.timerify");
  }
  get nodeTiming() {
    return nodeTiming;
  }
  eventLoopUtilization() {
    return {};
  }
  markResourceTiming() {
    return new PerformanceResourceTiming("");
  }
  onresourcetimingbufferfull = null;
  now() {
    if (this.timeOrigin === _timeOrigin) {
      return _performanceNow();
    }
    return Date.now() - this.timeOrigin;
  }
  clearMarks(markName) {
    this._entries = markName ? this._entries.filter((e) => e.name !== markName) : this._entries.filter((e) => e.entryType !== "mark");
  }
  clearMeasures(measureName) {
    this._entries = measureName ? this._entries.filter((e) => e.name !== measureName) : this._entries.filter((e) => e.entryType !== "measure");
  }
  clearResourceTimings() {
    this._entries = this._entries.filter((e) => e.entryType !== "resource" || e.entryType !== "navigation");
  }
  getEntries() {
    return this._entries;
  }
  getEntriesByName(name, type) {
    return this._entries.filter((e) => e.name === name && (!type || e.entryType === type));
  }
  getEntriesByType(type) {
    return this._entries.filter((e) => e.entryType === type);
  }
  mark(name, options) {
    const entry = new PerformanceMark(name, options);
    this._entries.push(entry);
    return entry;
  }
  measure(measureName, startOrMeasureOptions, endMark) {
    let start;
    let end;
    if (typeof startOrMeasureOptions === "string") {
      start = this.getEntriesByName(startOrMeasureOptions, "mark")[0]?.startTime;
      end = this.getEntriesByName(endMark, "mark")[0]?.startTime;
    } else {
      start = Number.parseFloat(startOrMeasureOptions?.start) || this.now();
      end = Number.parseFloat(startOrMeasureOptions?.end) || this.now();
    }
    const entry = new PerformanceMeasure(measureName, {
      startTime: start,
      detail: {
        start,
        end
      }
    });
    this._entries.push(entry);
    return entry;
  }
  setResourceTimingBufferSize(maxSize) {
    this._resourceTimingBufferSize = maxSize;
  }
  addEventListener(type, listener, options) {
    throw createNotImplementedError("Performance.addEventListener");
  }
  removeEventListener(type, listener, options) {
    throw createNotImplementedError("Performance.removeEventListener");
  }
  dispatchEvent(event) {
    throw createNotImplementedError("Performance.dispatchEvent");
  }
  toJSON() {
    return this;
  }
};
var PerformanceObserver = class {
  static {
    __name(this, "PerformanceObserver");
  }
  __unenv__ = true;
  static supportedEntryTypes = [];
  _callback = null;
  constructor(callback) {
    this._callback = callback;
  }
  takeRecords() {
    return [];
  }
  disconnect() {
    throw createNotImplementedError("PerformanceObserver.disconnect");
  }
  observe(options) {
    throw createNotImplementedError("PerformanceObserver.observe");
  }
  bind(fn) {
    return fn;
  }
  runInAsyncScope(fn, thisArg, ...args) {
    return fn.call(thisArg, ...args);
  }
  asyncId() {
    return 0;
  }
  triggerAsyncId() {
    return 0;
  }
  emitDestroy() {
    return this;
  }
};
var performance = globalThis.performance && "addEventListener" in globalThis.performance ? globalThis.performance : new Performance();

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/@cloudflare/unenv-preset/dist/runtime/polyfill/performance.mjs
if (!("__unenv__" in performance)) {
  const proto = Performance.prototype;
  for (const key of Object.getOwnPropertyNames(proto)) {
    if (key !== "constructor" && !(key in performance)) {
      const desc = Object.getOwnPropertyDescriptor(proto, key);
      if (desc) {
        Object.defineProperty(performance, key, desc);
      }
    }
  }
}
globalThis.performance = performance;
globalThis.Performance = Performance;
globalThis.PerformanceEntry = PerformanceEntry;
globalThis.PerformanceMark = PerformanceMark;
globalThis.PerformanceMeasure = PerformanceMeasure;
globalThis.PerformanceObserver = PerformanceObserver;
globalThis.PerformanceObserverEntryList = PerformanceObserverEntryList;
globalThis.PerformanceResourceTiming = PerformanceResourceTiming;

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/console.mjs
import { Writable } from "node:stream";

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/mock/noop.mjs
var noop_default = Object.assign(() => {
}, { __unenv__: true });

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/console.mjs
var _console = globalThis.console;
var _ignoreErrors = true;
var _stderr = new Writable();
var _stdout = new Writable();
var log = _console?.log ?? noop_default;
var info = _console?.info ?? log;
var trace = _console?.trace ?? info;
var debug = _console?.debug ?? log;
var table = _console?.table ?? log;
var error = _console?.error ?? log;
var warn = _console?.warn ?? error;
var createTask = _console?.createTask ?? /* @__PURE__ */ notImplemented("console.createTask");
var clear = _console?.clear ?? noop_default;
var count = _console?.count ?? noop_default;
var countReset = _console?.countReset ?? noop_default;
var dir = _console?.dir ?? noop_default;
var dirxml = _console?.dirxml ?? noop_default;
var group = _console?.group ?? noop_default;
var groupEnd = _console?.groupEnd ?? noop_default;
var groupCollapsed = _console?.groupCollapsed ?? noop_default;
var profile = _console?.profile ?? noop_default;
var profileEnd = _console?.profileEnd ?? noop_default;
var time = _console?.time ?? noop_default;
var timeEnd = _console?.timeEnd ?? noop_default;
var timeLog = _console?.timeLog ?? noop_default;
var timeStamp = _console?.timeStamp ?? noop_default;
var Console = _console?.Console ?? /* @__PURE__ */ notImplementedClass("console.Console");
var _times = /* @__PURE__ */ new Map();
var _stdoutErrorHandler = noop_default;
var _stderrErrorHandler = noop_default;

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/@cloudflare/unenv-preset/dist/runtime/node/console.mjs
var workerdConsole = globalThis["console"];
var {
  assert,
  clear: clear2,
  // @ts-expect-error undocumented public API
  context,
  count: count2,
  countReset: countReset2,
  // @ts-expect-error undocumented public API
  createTask: createTask2,
  debug: debug2,
  dir: dir2,
  dirxml: dirxml2,
  error: error2,
  group: group2,
  groupCollapsed: groupCollapsed2,
  groupEnd: groupEnd2,
  info: info2,
  log: log2,
  profile: profile2,
  profileEnd: profileEnd2,
  table: table2,
  time: time2,
  timeEnd: timeEnd2,
  timeLog: timeLog2,
  timeStamp: timeStamp2,
  trace: trace2,
  warn: warn2
} = workerdConsole;
Object.assign(workerdConsole, {
  Console,
  _ignoreErrors,
  _stderr,
  _stderrErrorHandler,
  _stdout,
  _stdoutErrorHandler,
  _times
});
var console_default = workerdConsole;

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/_virtual_unenv_global_polyfill-@cloudflare-unenv-preset-node-console
globalThis.console = console_default;

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/process/hrtime.mjs
var hrtime = /* @__PURE__ */ Object.assign(/* @__PURE__ */ __name(function hrtime2(startTime) {
  const now = Date.now();
  const seconds = Math.trunc(now / 1e3);
  const nanos = now % 1e3 * 1e6;
  if (startTime) {
    let diffSeconds = seconds - startTime[0];
    let diffNanos = nanos - startTime[0];
    if (diffNanos < 0) {
      diffSeconds = diffSeconds - 1;
      diffNanos = 1e9 + diffNanos;
    }
    return [diffSeconds, diffNanos];
  }
  return [seconds, nanos];
}, "hrtime"), { bigint: /* @__PURE__ */ __name(function bigint() {
  return BigInt(Date.now() * 1e6);
}, "bigint") });

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/process/process.mjs
import { EventEmitter } from "node:events";

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/tty/read-stream.mjs
var ReadStream = class {
  static {
    __name(this, "ReadStream");
  }
  fd;
  isRaw = false;
  isTTY = false;
  constructor(fd) {
    this.fd = fd;
  }
  setRawMode(mode) {
    this.isRaw = mode;
    return this;
  }
};

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/tty/write-stream.mjs
var WriteStream = class {
  static {
    __name(this, "WriteStream");
  }
  fd;
  columns = 80;
  rows = 24;
  isTTY = false;
  constructor(fd) {
    this.fd = fd;
  }
  clearLine(dir3, callback) {
    callback && callback();
    return false;
  }
  clearScreenDown(callback) {
    callback && callback();
    return false;
  }
  cursorTo(x, y, callback) {
    callback && typeof callback === "function" && callback();
    return false;
  }
  moveCursor(dx, dy, callback) {
    callback && callback();
    return false;
  }
  getColorDepth(env2) {
    return 1;
  }
  hasColors(count3, env2) {
    return false;
  }
  getWindowSize() {
    return [this.columns, this.rows];
  }
  write(str, encoding, cb) {
    if (str instanceof Uint8Array) {
      str = new TextDecoder().decode(str);
    }
    try {
      console.log(str);
    } catch {
    }
    cb && typeof cb === "function" && cb();
    return false;
  }
};

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/process/node-version.mjs
var NODE_VERSION = "22.14.0";

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/unenv/dist/runtime/node/internal/process/process.mjs
var Process = class _Process extends EventEmitter {
  static {
    __name(this, "Process");
  }
  env;
  hrtime;
  nextTick;
  constructor(impl) {
    super();
    this.env = impl.env;
    this.hrtime = impl.hrtime;
    this.nextTick = impl.nextTick;
    for (const prop of [...Object.getOwnPropertyNames(_Process.prototype), ...Object.getOwnPropertyNames(EventEmitter.prototype)]) {
      const value = this[prop];
      if (typeof value === "function") {
        this[prop] = value.bind(this);
      }
    }
  }
  // --- event emitter ---
  emitWarning(warning, type, code) {
    console.warn(`${code ? `[${code}] ` : ""}${type ? `${type}: ` : ""}${warning}`);
  }
  emit(...args) {
    return super.emit(...args);
  }
  listeners(eventName) {
    return super.listeners(eventName);
  }
  // --- stdio (lazy initializers) ---
  #stdin;
  #stdout;
  #stderr;
  get stdin() {
    return this.#stdin ??= new ReadStream(0);
  }
  get stdout() {
    return this.#stdout ??= new WriteStream(1);
  }
  get stderr() {
    return this.#stderr ??= new WriteStream(2);
  }
  // --- cwd ---
  #cwd = "/";
  chdir(cwd2) {
    this.#cwd = cwd2;
  }
  cwd() {
    return this.#cwd;
  }
  // --- dummy props and getters ---
  arch = "";
  platform = "";
  argv = [];
  argv0 = "";
  execArgv = [];
  execPath = "";
  title = "";
  pid = 200;
  ppid = 100;
  get version() {
    return `v${NODE_VERSION}`;
  }
  get versions() {
    return { node: NODE_VERSION };
  }
  get allowedNodeEnvironmentFlags() {
    return /* @__PURE__ */ new Set();
  }
  get sourceMapsEnabled() {
    return false;
  }
  get debugPort() {
    return 0;
  }
  get throwDeprecation() {
    return false;
  }
  get traceDeprecation() {
    return false;
  }
  get features() {
    return {};
  }
  get release() {
    return {};
  }
  get connected() {
    return false;
  }
  get config() {
    return {};
  }
  get moduleLoadList() {
    return [];
  }
  constrainedMemory() {
    return 0;
  }
  availableMemory() {
    return 0;
  }
  uptime() {
    return 0;
  }
  resourceUsage() {
    return {};
  }
  // --- noop methods ---
  ref() {
  }
  unref() {
  }
  // --- unimplemented methods ---
  umask() {
    throw createNotImplementedError("process.umask");
  }
  getBuiltinModule() {
    return void 0;
  }
  getActiveResourcesInfo() {
    throw createNotImplementedError("process.getActiveResourcesInfo");
  }
  exit() {
    throw createNotImplementedError("process.exit");
  }
  reallyExit() {
    throw createNotImplementedError("process.reallyExit");
  }
  kill() {
    throw createNotImplementedError("process.kill");
  }
  abort() {
    throw createNotImplementedError("process.abort");
  }
  dlopen() {
    throw createNotImplementedError("process.dlopen");
  }
  setSourceMapsEnabled() {
    throw createNotImplementedError("process.setSourceMapsEnabled");
  }
  loadEnvFile() {
    throw createNotImplementedError("process.loadEnvFile");
  }
  disconnect() {
    throw createNotImplementedError("process.disconnect");
  }
  cpuUsage() {
    throw createNotImplementedError("process.cpuUsage");
  }
  setUncaughtExceptionCaptureCallback() {
    throw createNotImplementedError("process.setUncaughtExceptionCaptureCallback");
  }
  hasUncaughtExceptionCaptureCallback() {
    throw createNotImplementedError("process.hasUncaughtExceptionCaptureCallback");
  }
  initgroups() {
    throw createNotImplementedError("process.initgroups");
  }
  openStdin() {
    throw createNotImplementedError("process.openStdin");
  }
  assert() {
    throw createNotImplementedError("process.assert");
  }
  binding() {
    throw createNotImplementedError("process.binding");
  }
  // --- attached interfaces ---
  permission = { has: /* @__PURE__ */ notImplemented("process.permission.has") };
  report = {
    directory: "",
    filename: "",
    signal: "SIGUSR2",
    compact: false,
    reportOnFatalError: false,
    reportOnSignal: false,
    reportOnUncaughtException: false,
    getReport: /* @__PURE__ */ notImplemented("process.report.getReport"),
    writeReport: /* @__PURE__ */ notImplemented("process.report.writeReport")
  };
  finalization = {
    register: /* @__PURE__ */ notImplemented("process.finalization.register"),
    unregister: /* @__PURE__ */ notImplemented("process.finalization.unregister"),
    registerBeforeExit: /* @__PURE__ */ notImplemented("process.finalization.registerBeforeExit")
  };
  memoryUsage = Object.assign(() => ({
    arrayBuffers: 0,
    rss: 0,
    external: 0,
    heapTotal: 0,
    heapUsed: 0
  }), { rss: /* @__PURE__ */ __name(() => 0, "rss") });
  // --- undefined props ---
  mainModule = void 0;
  domain = void 0;
  // optional
  send = void 0;
  exitCode = void 0;
  channel = void 0;
  getegid = void 0;
  geteuid = void 0;
  getgid = void 0;
  getgroups = void 0;
  getuid = void 0;
  setegid = void 0;
  seteuid = void 0;
  setgid = void 0;
  setgroups = void 0;
  setuid = void 0;
  // internals
  _events = void 0;
  _eventsCount = void 0;
  _exiting = void 0;
  _maxListeners = void 0;
  _debugEnd = void 0;
  _debugProcess = void 0;
  _fatalException = void 0;
  _getActiveHandles = void 0;
  _getActiveRequests = void 0;
  _kill = void 0;
  _preload_modules = void 0;
  _rawDebug = void 0;
  _startProfilerIdleNotifier = void 0;
  _stopProfilerIdleNotifier = void 0;
  _tickCallback = void 0;
  _disconnect = void 0;
  _handleQueue = void 0;
  _pendingMessage = void 0;
  _channel = void 0;
  _send = void 0;
  _linkedBinding = void 0;
};

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/@cloudflare/unenv-preset/dist/runtime/node/process.mjs
var globalProcess = globalThis["process"];
var getBuiltinModule = globalProcess.getBuiltinModule;
var workerdProcess = getBuiltinModule("node:process");
var unenvProcess = new Process({
  env: globalProcess.env,
  hrtime,
  // `nextTick` is available from workerd process v1
  nextTick: workerdProcess.nextTick
});
var { exit, features, platform } = workerdProcess;
var {
  _channel,
  _debugEnd,
  _debugProcess,
  _disconnect,
  _events,
  _eventsCount,
  _exiting,
  _fatalException,
  _getActiveHandles,
  _getActiveRequests,
  _handleQueue,
  _kill,
  _linkedBinding,
  _maxListeners,
  _pendingMessage,
  _preload_modules,
  _rawDebug,
  _send,
  _startProfilerIdleNotifier,
  _stopProfilerIdleNotifier,
  _tickCallback,
  abort,
  addListener,
  allowedNodeEnvironmentFlags,
  arch,
  argv,
  argv0,
  assert: assert2,
  availableMemory,
  binding,
  channel,
  chdir,
  config,
  connected,
  constrainedMemory,
  cpuUsage,
  cwd,
  debugPort,
  disconnect,
  dlopen,
  domain,
  emit,
  emitWarning,
  env,
  eventNames,
  execArgv,
  execPath,
  exitCode,
  finalization,
  getActiveResourcesInfo,
  getegid,
  geteuid,
  getgid,
  getgroups,
  getMaxListeners,
  getuid,
  hasUncaughtExceptionCaptureCallback,
  hrtime: hrtime3,
  initgroups,
  kill,
  listenerCount,
  listeners,
  loadEnvFile,
  mainModule,
  memoryUsage,
  moduleLoadList,
  nextTick,
  off,
  on,
  once,
  openStdin,
  permission,
  pid,
  ppid,
  prependListener,
  prependOnceListener,
  rawListeners,
  reallyExit,
  ref,
  release,
  removeAllListeners,
  removeListener,
  report,
  resourceUsage,
  send,
  setegid,
  seteuid,
  setgid,
  setgroups,
  setMaxListeners,
  setSourceMapsEnabled,
  setuid,
  setUncaughtExceptionCaptureCallback,
  sourceMapsEnabled,
  stderr,
  stdin,
  stdout,
  throwDeprecation,
  title,
  traceDeprecation,
  umask,
  unref,
  uptime,
  version,
  versions
} = unenvProcess;
var _process = {
  abort,
  addListener,
  allowedNodeEnvironmentFlags,
  hasUncaughtExceptionCaptureCallback,
  setUncaughtExceptionCaptureCallback,
  loadEnvFile,
  sourceMapsEnabled,
  arch,
  argv,
  argv0,
  chdir,
  config,
  connected,
  constrainedMemory,
  availableMemory,
  cpuUsage,
  cwd,
  debugPort,
  dlopen,
  disconnect,
  emit,
  emitWarning,
  env,
  eventNames,
  execArgv,
  execPath,
  exit,
  finalization,
  features,
  getBuiltinModule,
  getActiveResourcesInfo,
  getMaxListeners,
  hrtime: hrtime3,
  kill,
  listeners,
  listenerCount,
  memoryUsage,
  nextTick,
  on,
  off,
  once,
  pid,
  platform,
  ppid,
  prependListener,
  prependOnceListener,
  rawListeners,
  release,
  removeAllListeners,
  removeListener,
  report,
  resourceUsage,
  setMaxListeners,
  setSourceMapsEnabled,
  stderr,
  stdin,
  stdout,
  title,
  throwDeprecation,
  traceDeprecation,
  umask,
  uptime,
  version,
  versions,
  // @ts-expect-error old API
  domain,
  initgroups,
  moduleLoadList,
  reallyExit,
  openStdin,
  assert: assert2,
  binding,
  send,
  exitCode,
  channel,
  getegid,
  geteuid,
  getgid,
  getgroups,
  getuid,
  setegid,
  seteuid,
  setgid,
  setgroups,
  setuid,
  permission,
  mainModule,
  _events,
  _eventsCount,
  _exiting,
  _maxListeners,
  _debugEnd,
  _debugProcess,
  _fatalException,
  _getActiveHandles,
  _getActiveRequests,
  _kill,
  _preload_modules,
  _rawDebug,
  _startProfilerIdleNotifier,
  _stopProfilerIdleNotifier,
  _tickCallback,
  _disconnect,
  _handleQueue,
  _pendingMessage,
  _channel,
  _send,
  _linkedBinding
};
var process_default = _process;

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/_virtual_unenv_global_polyfill-@cloudflare-unenv-preset-node-process
globalThis.process = process_default;

// _shared/battlenet.js
var jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "authorization, content-type"
};
function handleOptions() {
  return new Response(null, { status: 204, headers: jsonHeaders });
}
__name(handleOptions, "handleOptions");
function json(data, init = {}) {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: {
      ...jsonHeaders,
      ...init.headers ?? {}
    }
  });
}
__name(json, "json");
function getBearerToken(request) {
  const authorization = request.headers.get("authorization") ?? "";
  if (authorization.toLowerCase().startsWith("bearer ")) {
    return authorization.slice(7).trim();
  }
  return new URL(request.url).searchParams.get("token") ?? "";
}
__name(getBearerToken, "getBearerToken");
function requireEnv(env2, key) {
  const value = env2[key];
  if (!value) {
    throw new Error(`Missing Cloudflare secret: ${key}`);
  }
  return value;
}
__name(requireEnv, "requireEnv");
async function getBattleNetServerToken(env2) {
  const params = new URLSearchParams();
  params.set("grant_type", "client_credentials");
  const result = await fetch("https://eu.battle.net/oauth/token", {
    method: "POST",
    headers: {
      "authorization": basicAuth(env2),
      "content-type": "application/x-www-form-urlencoded"
    },
    body: params
  });
  return readBattleNetResponse(result).then((data) => data.access_token);
}
__name(getBattleNetServerToken, "getBattleNetServerToken");
async function fetchBattleNetJson(path, { token, params = {} } = {}) {
  const url = new URL(path);
  for (const [key, value] of Object.entries(params)) {
    if (value != null && value !== "") {
      url.searchParams.set(key, value);
    }
  }
  const result = await fetch(url, {
    headers: {
      "authorization": `Bearer ${token}`
    }
  });
  return readBattleNetResponse(result);
}
__name(fetchBattleNetJson, "fetchBattleNetJson");
async function readBattleNetResponse(result) {
  const text = await result.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = { message: text };
  }
  if (!result.ok) {
    const error3 = new Error("Battle.net request failed");
    error3.status = result.status;
    error3.data = data;
    throw error3;
  }
  return data;
}
__name(readBattleNetResponse, "readBattleNetResponse");
function validateRedirectUri(env2, redirectUri) {
  const allowed = (env2.BATTLENET_ALLOWED_REDIRECT_URIS ?? "").split(",").map((value) => value.trim()).filter(Boolean);
  if (allowed.length === 0) {
    return;
  }
  if (!allowed.includes(redirectUri)) {
    const error3 = new Error("Redirect URI is not allowed");
    error3.status = 400;
    error3.data = { error: "invalid_redirect_uri" };
    throw error3;
  }
}
__name(validateRedirectUri, "validateRedirectUri");
function toErrorResponse(error3) {
  return json(
    {
      status: error3.status ?? 500,
      data: error3.data ?? null,
      message: error3.message ?? String(error3)
    },
    { status: error3.status ?? 500 }
  );
}
__name(toErrorResponse, "toErrorResponse");
function basicAuth(env2) {
  const clientId = requireEnv(env2, "BATTLENET_CLIENT_ID");
  const clientSecret = requireEnv(env2, "BATTLENET_CLIENT_SECRET");
  const credentials = `${clientId}:${clientSecret}`;
  return `Basic ${btoa(credentials)}`;
}
__name(basicAuth, "basicAuth");

// api/exchangeBattleNetCode.js
async function onRequest({ request, env: env2 }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const url = new URL(request.url);
    const code = url.searchParams.get("code");
    const redirectUri = url.searchParams.get("redirectUri");
    if (!code || !redirectUri) {
      return json({ error: "missing_parameters" }, { status: 400 });
    }
    validateRedirectUri(env2, redirectUri);
    const params = new URLSearchParams();
    params.set("grant_type", "authorization_code");
    params.set("code", code);
    params.set("redirect_uri", redirectUri);
    const credentials = `${requireEnv(env2, "BATTLENET_CLIENT_ID")}:${requireEnv(
      env2,
      "BATTLENET_CLIENT_SECRET"
    )}`;
    const result = await fetch("https://eu.battle.net/oauth/token", {
      method: "POST",
      headers: {
        "authorization": `Basic ${btoa(credentials)}`,
        "content-type": "application/x-www-form-urlencoded"
      },
      body: params
    });
    return json(await readBattleNetResponse(result));
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest, "onRequest");

// api/getCharacterAchievements.js
async function onRequest2({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const url = new URL(request.url);
    const token = getBearerToken(request);
    const realmSlug = url.searchParams.get("realmSlug");
    const characterName = url.searchParams.get("characterName");
    if (!token || !realmSlug || !characterName) {
      return json({ error: "missing_parameters" }, { status: 400 });
    }
    const characterSlug = encodeURIComponent(characterName.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${realmSlug}/${characterSlug}/achievements`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest2, "onRequest");

// api/getCollectibleMedia.js
var namespace = "static-eu";
var locale = "fr_FR";
async function onRequest3({ request, env: env2 }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const url = new URL(request.url);
    const type = url.searchParams.get("type");
    const id = url.searchParams.get("id");
    if (!type || !id) {
      return json({ error: "missing_type_or_id" }, { status: 400 });
    }
    if (!/^\d+$/.test(id)) {
      return json({ error: "invalid_id" }, { status: 400 });
    }
    const token = await getBattleNetServerToken(env2);
    const mediaUrl = await getMediaUrl({ type, id, token });
    return json(
      { url: mediaUrl },
      {
        headers: {
          "cache-control": "public, max-age=86400"
        }
      }
    );
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest3, "onRequest");
async function getMediaUrl({ type, id, token }) {
  if (type === "mount") {
    return getMountMediaUrl({ id, token });
  }
  if (type === "pet") {
    return getPetMediaUrl({ id, token });
  }
  return null;
}
__name(getMediaUrl, "getMediaUrl");
async function getMountMediaUrl({ id, token }) {
  const mount = await fetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/mount/${id}`,
    {
      token,
      params: { namespace, locale }
    }
  );
  const displays = Array.isArray(mount.creature_displays) ? mount.creature_displays : [];
  for (const display of displays) {
    const media = await getLinkedMedia({
      token,
      href: display.key?.href,
      fallbackPath: display.id ? `https://eu.api.blizzard.com/data/wow/media/creature-display/${display.id}` : ""
    });
    const mediaUrl = pickMediaUrl(media);
    if (mediaUrl) return mediaUrl;
  }
  return null;
}
__name(getMountMediaUrl, "getMountMediaUrl");
async function getPetMediaUrl({ id, token }) {
  const directMedia = await tryFetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/media/pet/${id}`,
    {
      token,
      params: { namespace, locale }
    }
  );
  const directMediaUrl = pickMediaUrl(directMedia);
  if (directMediaUrl) return directMediaUrl;
  const pet = await tryFetchBattleNetJson(
    `https://eu.api.blizzard.com/data/wow/pet/${id}`,
    {
      token,
      params: { namespace, locale }
    }
  );
  const linkedMedia = await getLinkedMedia({
    token,
    href: pet?.media?.key?.href
  });
  return pickMediaUrl(linkedMedia);
}
__name(getPetMediaUrl, "getPetMediaUrl");
async function getLinkedMedia({ token, href, fallbackPath = "" }) {
  const path = href || fallbackPath;
  if (!path) return null;
  return tryFetchBattleNetJson(path, {
    token,
    params: { namespace, locale }
  });
}
__name(getLinkedMedia, "getLinkedMedia");
async function tryFetchBattleNetJson(path, options) {
  try {
    return await fetchBattleNetJson(path, options);
  } catch (_) {
    return null;
  }
}
__name(tryFetchBattleNetJson, "tryFetchBattleNetJson");
function pickMediaUrl(media) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred = assets.find((asset) => asset.key === "zoom") ?? assets.find((asset) => asset.key === "main") ?? assets.find((asset) => asset.key === "default") ?? assets.find((asset) => typeof asset.value === "string");
  return preferred?.value ?? null;
}
__name(pickMediaUrl, "pickMediaUrl");

// api/getMountCatalog.js
async function onRequest4({ request, env: env2 }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = await getBattleNetServerToken(env2);
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/data/wow/mount/index",
      {
        token,
        params: {
          namespace: "static-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest4, "onRequest");

// api/getMountDetails.js
async function onRequest5({ request, env: env2 }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const id = new URL(request.url).searchParams.get("id");
    if (!id) {
      return json({ error: "missing_id" }, { status: 400 });
    }
    const token = await getBattleNetServerToken(env2);
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/data/wow/mount/${id}`,
      {
        token,
        params: {
          namespace: "static-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest5, "onRequest");

// api/getWowAchievements.js
async function onRequest6({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = getBearerToken(request);
    if (!token) {
      return json({ error: "missing_token" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow/collections/achievements",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest6, "onRequest");

// api/getWowCharacterProfile.js
async function onRequest7({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const url = new URL(request.url);
    const token = getBearerToken(request);
    const region = normalizeRegion(url.searchParams.get("region"));
    const realmSlug = slugify(url.searchParams.get("realmSlug"));
    const characterName = url.searchParams.get("characterName")?.trim() ?? "";
    if (!token || !region || !realmSlug || !characterName) {
      return json({ error: "missing_parameters" }, { status: 400 });
    }
    const characterSlug = encodeURIComponent(characterName.toLowerCase());
    const params = {
      namespace: `profile-${region}`,
      locale: localeForRegion(region)
    };
    const [profile3, portraitUrl] = await Promise.all([
      fetchBattleNetJson(
        `https://${region}.api.blizzard.com/profile/wow/character/${realmSlug}/${characterSlug}`,
        { token, params }
      ),
      fetchCharacterPortraitUrl(token, region, realmSlug, characterSlug, params)
    ]);
    return json(toCharacterSummary(profile3, region, portraitUrl));
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest7, "onRequest");
async function fetchCharacterPortraitUrl(token, region, realmSlug, characterSlug, params) {
  try {
    const media = await fetchBattleNetJson(
      `https://${region}.api.blizzard.com/profile/wow/character/${realmSlug}/${characterSlug}/character-media`,
      { token, params }
    );
    return pickCharacterPortraitUrl(media);
  } catch (_) {
    return null;
  }
}
__name(fetchCharacterPortraitUrl, "fetchCharacterPortraitUrl");
function toCharacterSummary(profile3, region, portraitUrl) {
  return {
    region: region.toUpperCase(),
    name: profile3.name ?? "",
    level: profile3.level ?? 0,
    realm: profile3.realm?.name ?? "",
    realmSlug: profile3.realm?.slug ?? "",
    race: profile3.playable_race?.name ?? "",
    characterClass: profile3.playable_class?.name ?? "",
    faction: profile3.faction?.name ?? "",
    guildName: profile3.guild?.name ?? null,
    guildRealm: profile3.guild?.realm?.name ?? null,
    guildRealmSlug: profile3.guild?.realm?.slug ?? null,
    achievementPoints: profile3.achievement_points ?? 0,
    portraitUrl
  };
}
__name(toCharacterSummary, "toCharacterSummary");
function pickCharacterPortraitUrl(media) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred = assets.find((asset) => asset.key === "inset") ?? assets.find((asset) => asset.key === "avatar") ?? assets.find((asset) => asset.key === "main-raw") ?? assets.find((asset) => asset.key === "main") ?? assets.find((asset) => typeof asset.value === "string");
  return preferred?.value ?? null;
}
__name(pickCharacterPortraitUrl, "pickCharacterPortraitUrl");
function normalizeRegion(value) {
  const region = (value ?? "eu").trim().toLowerCase();
  const allowedRegions = /* @__PURE__ */ new Set(["eu", "us", "kr", "tw"]);
  return allowedRegions.has(region) ? region : null;
}
__name(normalizeRegion, "normalizeRegion");
function localeForRegion(region) {
  switch (region) {
    case "us":
      return "en_US";
    case "kr":
      return "ko_KR";
    case "tw":
      return "zh_TW";
    default:
      return "fr_FR";
  }
}
__name(localeForRegion, "localeForRegion");
function slugify(value) {
  return (value ?? "").trim().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/['’]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}
__name(slugify, "slugify");

// api/getWowCharacters.js
async function onRequest8({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = getBearerToken(request);
    if (!token) {
      return json({ error: "missing_token" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    const accounts = data.wow_accounts ?? [];
    const characterSummaries = [];
    for (const account of accounts) {
      const characters = account.characters ?? [];
      for (const character of characters) {
        characterSummaries.push({
          name: character.name,
          level: character.level,
          realm: character.realm?.name,
          race: character.playable_race?.name,
          characterClass: character.playable_class?.name,
          faction: character.faction?.name,
          realmSlug: character.realm?.slug
        });
      }
    }
    const finalCharacters = await Promise.all(
      characterSummaries.map(async (character) => {
        const [
          professions,
          profile3,
          portraitUrl,
          mythicKeystoneRating
        ] = await Promise.all([
          fetchCharacterProfessions(token, character),
          fetchCharacterProfile(token, character),
          fetchCharacterPortraitUrl2(token, character),
          fetchCharacterMythicKeystoneRating(token, character)
        ]);
        return {
          ...character,
          professions,
          achievementPoints: profile3.achievement_points ?? 0,
          mythicKeystoneRating,
          portraitUrl
        };
      })
    );
    finalCharacters.sort((a, b) => b.level - a.level);
    return json(finalCharacters);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest8, "onRequest");
async function fetchCharacterMythicKeystoneRating(token, character) {
  if (!character.realmSlug || !character.name) {
    return 0;
  }
  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/mythic-keystone-profile`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return ratingFromMythicKeystoneProfile(data);
  } catch (_) {
    return 0;
  }
}
__name(fetchCharacterMythicKeystoneRating, "fetchCharacterMythicKeystoneRating");
async function fetchCharacterProfile(token, character) {
  if (!character.realmSlug || !character.name) {
    return {};
  }
  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    return await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
  } catch (_) {
    return {};
  }
}
__name(fetchCharacterProfile, "fetchCharacterProfile");
async function fetchCharacterPortraitUrl2(token, character) {
  if (!character.realmSlug || !character.name) {
    return null;
  }
  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/character-media`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return pickCharacterPortraitUrl2(data);
  } catch (_) {
    return null;
  }
}
__name(fetchCharacterPortraitUrl2, "fetchCharacterPortraitUrl");
async function fetchCharacterProfessions(token, character) {
  if (!character.realmSlug || !character.name) {
    return [];
  }
  try {
    const characterSlug = encodeURIComponent(character.name.toLowerCase());
    const data = await fetchBattleNetJson(
      `https://eu.api.blizzard.com/profile/wow/character/${character.realmSlug}/${characterSlug}/professions`,
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return collectProfessionNames(data);
  } catch (_) {
    return [];
  }
}
__name(fetchCharacterProfessions, "fetchCharacterProfessions");
function collectProfessionNames(data) {
  const names = /* @__PURE__ */ new Set();
  const entries = [
    ...Array.isArray(data?.primaries) ? data.primaries : [],
    ...Array.isArray(data?.secondaries) ? data.secondaries : [],
    ...Array.isArray(data?.professions) ? data.professions : []
  ];
  for (const entry of entries) {
    addProfessionName(names, entry);
  }
  return [...names];
}
__name(collectProfessionNames, "collectProfessionNames");
function addProfessionName(names, value) {
  if (!value) return;
  if (typeof value === "string") {
    const name = value.trim();
    if (name) names.add(name);
    return;
  }
  if (typeof value !== "object") return;
  addProfessionName(names, value.profession);
  addProfessionName(names, value.name);
}
__name(addProfessionName, "addProfessionName");
function ratingFromMythicKeystoneProfile(profile3) {
  const rating = profile3?.current_mythic_rating?.rating;
  if (typeof rating === "number") {
    return Math.round(rating);
  }
  if (typeof rating === "string") {
    const parsed = Number.parseFloat(rating);
    return Number.isFinite(parsed) ? Math.round(parsed) : 0;
  }
  return 0;
}
__name(ratingFromMythicKeystoneProfile, "ratingFromMythicKeystoneProfile");
function pickCharacterPortraitUrl2(media) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  const preferred = assets.find((asset) => asset.key === "inset") ?? assets.find((asset) => asset.key === "avatar") ?? assets.find((asset) => asset.key === "main-raw") ?? assets.find((asset) => asset.key === "main") ?? assets.find((asset) => typeof asset.value === "string");
  return preferred?.value ?? null;
}
__name(pickCharacterPortraitUrl2, "pickCharacterPortraitUrl");

// api/getWowGuildRoster.js
async function onRequest9({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const url = new URL(request.url);
    const token = getBearerToken(request);
    const region = normalizeRegion2(url.searchParams.get("region"));
    const realmSlug = slugify2(url.searchParams.get("realmSlug"));
    const guildSlug = slugify2(url.searchParams.get("guildName"));
    if (!token || !region || !realmSlug || !guildSlug) {
      return json({ error: "missing_parameters" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      `https://${region}.api.blizzard.com/data/wow/guild/${realmSlug}/${guildSlug}/roster`,
      {
        token,
        params: {
          namespace: `profile-${region}`,
          locale: localeForRegion2(region)
        }
      }
    );
    const members = Array.isArray(data.members) ? data.members : [];
    const guildName = data.guild?.name ?? url.searchParams.get("guildName");
    const guildRealm = data.guild?.realm?.name ?? "";
    const guildRealmSlug = data.guild?.realm?.slug ?? realmSlug;
    return json(
      members.map(
        (entry) => toGuildMemberSummary(
          entry,
          region,
          guildName,
          guildRealm,
          guildRealmSlug
        )
      ).filter((entry) => entry.name && entry.realmSlug)
    );
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest9, "onRequest");
function toGuildMemberSummary(entry, region, guildName, guildRealm, guildRealmSlug) {
  const character = entry.character ?? {};
  return {
    region: region.toUpperCase(),
    name: character.name ?? "",
    level: character.level ?? 0,
    realm: character.realm?.name ?? guildRealm,
    realmSlug: character.realm?.slug ?? guildRealmSlug,
    race: character.playable_race?.name ?? "",
    characterClass: character.playable_class?.name ?? "",
    faction: "",
    guildName,
    guildRealm,
    guildRealmSlug,
    achievementPoints: 0,
    portraitUrl: null
  };
}
__name(toGuildMemberSummary, "toGuildMemberSummary");
function normalizeRegion2(value) {
  const region = (value ?? "eu").trim().toLowerCase();
  const allowedRegions = /* @__PURE__ */ new Set(["eu", "us", "kr", "tw"]);
  return allowedRegions.has(region) ? region : null;
}
__name(normalizeRegion2, "normalizeRegion");
function localeForRegion2(region) {
  switch (region) {
    case "us":
      return "en_US";
    case "kr":
      return "ko_KR";
    case "tw":
      return "zh_TW";
    default:
      return "fr_FR";
  }
}
__name(localeForRegion2, "localeForRegion");
function slugify2(value) {
  return (value ?? "").trim().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/['’]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}
__name(slugify2, "slugify");

// api/getWowMounts.js
async function onRequest10({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = getBearerToken(request);
    if (!token) {
      return json({ error: "missing_token" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow/collections/mounts",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest10, "onRequest");

// api/getWowPets.js
async function onRequest11({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = getBearerToken(request);
    if (!token) {
      return json({ error: "missing_token" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow/collections/pets",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest11, "onRequest");

// api/getWowProfile.js
async function onRequest12({ request }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    const token = getBearerToken(request);
    if (!token) {
      return json({ error: "missing_token" }, { status: 400 });
    }
    const data = await fetchBattleNetJson(
      "https://eu.api.blizzard.com/profile/user/wow",
      {
        token,
        params: {
          namespace: "profile-eu",
          locale: "fr_FR"
        }
      }
    );
    return json(data);
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest12, "onRequest");

// api/revenueCatWebhook.js
var firestoreDatabase = "(default)";
var cachedGoogleAccessToken = null;
async function onRequest13({ request, env: env2 }) {
  if (request.method === "OPTIONS") return handleOptions();
  try {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, { status: 405 });
    }
    const expectedAuthorization = env2.REVENUECAT_WEBHOOK_AUTHORIZATION?.trim();
    if (expectedAuthorization) {
      const authorization = request.headers.get("authorization")?.trim() ?? "";
      if (authorization !== expectedAuthorization) {
        return json({ error: "unauthorized" }, { status: 401 });
      }
    }
    const body = await request.json();
    const event = body?.event;
    if (!event || typeof event !== "object") {
      return json({ error: "missing_event" }, { status: 400 });
    }
    const status = premiumStatusFromWebhookEvent(env2, event);
    if (status == null) {
      return json({
        ok: true,
        ignored: true,
        reason: "event_does_not_reference_premium_entitlement"
      });
    }
    const userIds = revenueCatUserCandidates(event);
    if (userIds.length === 0) {
      return json({ error: "missing_app_user_id" }, { status: 400 });
    }
    const updatedUsers = await syncPremiumStatusForUsers(env2, userIds, status, event);
    return json({
      ok: true,
      isPremium: status.isPremium,
      updatedUsers
    });
  } catch (error3) {
    return toErrorResponse(error3);
  }
}
__name(onRequest13, "onRequest");
function premiumStatusFromWebhookEvent(env2, event) {
  const entitlementIds = revenueCatEntitlementIds(event);
  if (!hasPremiumEntitlement(env2, entitlementIds)) {
    return null;
  }
  const expirationAt = dateFromMillis(event.expiration_at_ms);
  const type = event.type ?? "";
  const isExpiration = type === "EXPIRATION";
  const isPremium = !isExpiration && (expirationAt == null || expirationAt.getTime() > Date.now());
  return {
    isPremium,
    entitlementIds: isPremium ? entitlementIds : [],
    expirationAt,
    source: "revenuecat_webhook"
  };
}
__name(premiumStatusFromWebhookEvent, "premiumStatusFromWebhookEvent");
function hasPremiumEntitlement(env2, entitlementIds) {
  const identifiers = [
    env2.REVENUECAT_PREMIUM_ENTITLEMENT_ID?.trim() || "WoW100% Premium",
    env2.REVENUECAT_PREMIUM_ENTITLEMENT_REST_ID?.trim() || "ent1288ffbccce"
  ].filter(Boolean);
  return entitlementIds.some((entitlementId) => identifiers.includes(entitlementId));
}
__name(hasPremiumEntitlement, "hasPremiumEntitlement");
function revenueCatEntitlementIds(event) {
  const ids = /* @__PURE__ */ new Set();
  addString(ids, event.entitlement_id);
  if (Array.isArray(event.entitlement_ids)) {
    for (const entitlementId of event.entitlement_ids) {
      addString(ids, entitlementId);
    }
  }
  return [...ids];
}
__name(revenueCatEntitlementIds, "revenueCatEntitlementIds");
function revenueCatUserCandidates(event) {
  const ids = /* @__PURE__ */ new Set();
  addString(ids, event.app_user_id);
  addString(ids, event.original_app_user_id);
  if (Array.isArray(event.aliases)) {
    for (const alias of event.aliases) {
      addString(ids, alias);
    }
  }
  return [...ids];
}
__name(revenueCatUserCandidates, "revenueCatUserCandidates");
function addString(ids, value) {
  if (typeof value !== "string") return;
  const trimmed = value.trim();
  if (trimmed) {
    ids.add(trimmed);
  }
}
__name(addString, "addString");
function dateFromMillis(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    return null;
  }
  return new Date(value);
}
__name(dateFromMillis, "dateFromMillis");
async function syncPremiumStatusForUsers(env2, userIds, status, event) {
  const accessToken = await getGoogleAccessToken(env2);
  const projectId = requireEnv(env2, "FIREBASE_PROJECT_ID");
  const results = await Promise.all(
    userIds.map(
      (userId) => syncPremiumStatusForUser({ env: env2, projectId, accessToken, userId, status, event })
    )
  );
  return results.filter(Boolean).length;
}
__name(syncPremiumStatusForUsers, "syncPremiumStatusForUsers");
async function syncPremiumStatusForUser({
  projectId,
  accessToken,
  userId,
  status,
  event
}) {
  const documentPath = firestoreDocumentPath(projectId, userId);
  const existing = await fetch(documentPath, {
    headers: { authorization: `Bearer ${accessToken}` }
  });
  if (existing.status === 404) {
    return false;
  }
  if (!existing.ok) {
    await throwFirestoreError(existing);
  }
  const now = (/* @__PURE__ */ new Date()).toISOString();
  const updateUrl = new URL(documentPath);
  for (const fieldPath of [
    "isPremium",
    "premiumSource",
    "premiumExpirationAt",
    "premiumEntitlements",
    "revenueCatAppUserId",
    "revenueCatManagementUrl",
    "revenueCatUpdatedAt",
    "updatedAt"
  ]) {
    updateUrl.searchParams.append("updateMask.fieldPaths", fieldPath);
  }
  const result = await fetch(updateUrl, {
    method: "PATCH",
    headers: {
      authorization: `Bearer ${accessToken}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      fields: {
        isPremium: { booleanValue: status.isPremium },
        premiumSource: { stringValue: status.source },
        premiumExpirationAt: firestoreNullableTimestamp(status.expirationAt),
        premiumEntitlements: firestoreStringArray(status.entitlementIds),
        revenueCatAppUserId: { stringValue: event.app_user_id ?? userId },
        revenueCatManagementUrl: { nullValue: "NULL_VALUE" },
        revenueCatUpdatedAt: { timestampValue: now },
        updatedAt: { timestampValue: now }
      }
    })
  });
  if (!result.ok) {
    await throwFirestoreError(result);
  }
  return true;
}
__name(syncPremiumStatusForUser, "syncPremiumStatusForUser");
function firestoreDocumentPath(projectId, userId) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(firestoreDatabase)}/documents/users/${encodeURIComponent(userId)}`;
}
__name(firestoreDocumentPath, "firestoreDocumentPath");
function firestoreNullableTimestamp(value) {
  if (value == null) {
    return { nullValue: "NULL_VALUE" };
  }
  return { timestampValue: value.toISOString() };
}
__name(firestoreNullableTimestamp, "firestoreNullableTimestamp");
function firestoreStringArray(values) {
  return {
    arrayValue: {
      values: values.map((value) => ({ stringValue: value }))
    }
  };
}
__name(firestoreStringArray, "firestoreStringArray");
async function throwFirestoreError(result) {
  const text = await result.text();
  const error3 = new Error("Firestore request failed");
  error3.status = result.status;
  error3.data = text ? JSON.parse(text) : null;
  throw error3;
}
__name(throwFirestoreError, "throwFirestoreError");
async function getGoogleAccessToken(env2) {
  const nowSeconds = Math.floor(Date.now() / 1e3);
  if (cachedGoogleAccessToken && cachedGoogleAccessToken.expiresAt > nowSeconds + 60) {
    return cachedGoogleAccessToken.token;
  }
  const clientEmail = requireEnv(env2, "FIREBASE_SERVICE_ACCOUNT_EMAIL");
  const privateKey = requireEnv(env2, "FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY").replaceAll("\\n", "\n");
  const assertion = await createGoogleJwt({ clientEmail, privateKey, nowSeconds });
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion
    })
  });
  const data = await response.json();
  if (!response.ok) {
    const error3 = new Error("Google OAuth token request failed");
    error3.status = response.status;
    error3.data = data;
    throw error3;
  }
  cachedGoogleAccessToken = {
    token: data.access_token,
    expiresAt: nowSeconds + Math.max(0, Number(data.expires_in ?? 0))
  };
  return cachedGoogleAccessToken.token;
}
__name(getGoogleAccessToken, "getGoogleAccessToken");
async function createGoogleJwt({ clientEmail, privateKey, nowSeconds }) {
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600
  };
  const signingInput = `${base64UrlJson(header)}.${base64UrlJson(payload)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput)
  );
  return `${signingInput}.${base64Url(signature)}`;
}
__name(createGoogleJwt, "createGoogleJwt");
function base64UrlJson(value) {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}
__name(base64UrlJson, "base64UrlJson");
function pemToArrayBuffer(pem) {
  const base64 = pem.replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "").replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}
__name(pemToArrayBuffer, "pemToArrayBuffer");
function base64Url(value) {
  const bytes = value instanceof ArrayBuffer ? new Uint8Array(value) : value;
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}
__name(base64Url, "base64Url");

// ../.wrangler/tmp/pages-zu0iXb/functionsRoutes-0.08387705237064891.mjs
var routes = [
  {
    routePath: "/api/exchangeBattleNetCode",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest]
  },
  {
    routePath: "/api/getCharacterAchievements",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest2]
  },
  {
    routePath: "/api/getCollectibleMedia",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest3]
  },
  {
    routePath: "/api/getMountCatalog",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest4]
  },
  {
    routePath: "/api/getMountDetails",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest5]
  },
  {
    routePath: "/api/getWowAchievements",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest6]
  },
  {
    routePath: "/api/getWowCharacterProfile",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest7]
  },
  {
    routePath: "/api/getWowCharacters",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest8]
  },
  {
    routePath: "/api/getWowGuildRoster",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest9]
  },
  {
    routePath: "/api/getWowMounts",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest10]
  },
  {
    routePath: "/api/getWowPets",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest11]
  },
  {
    routePath: "/api/getWowProfile",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest12]
  },
  {
    routePath: "/api/revenueCatWebhook",
    mountPath: "/api",
    method: "",
    middlewares: [],
    modules: [onRequest13]
  }
];

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/path-to-regexp/dist.es2015/index.js
function lexer(str) {
  var tokens = [];
  var i = 0;
  while (i < str.length) {
    var char = str[i];
    if (char === "*" || char === "+" || char === "?") {
      tokens.push({ type: "MODIFIER", index: i, value: str[i++] });
      continue;
    }
    if (char === "\\") {
      tokens.push({ type: "ESCAPED_CHAR", index: i++, value: str[i++] });
      continue;
    }
    if (char === "{") {
      tokens.push({ type: "OPEN", index: i, value: str[i++] });
      continue;
    }
    if (char === "}") {
      tokens.push({ type: "CLOSE", index: i, value: str[i++] });
      continue;
    }
    if (char === ":") {
      var name = "";
      var j = i + 1;
      while (j < str.length) {
        var code = str.charCodeAt(j);
        if (
          // `0-9`
          code >= 48 && code <= 57 || // `A-Z`
          code >= 65 && code <= 90 || // `a-z`
          code >= 97 && code <= 122 || // `_`
          code === 95
        ) {
          name += str[j++];
          continue;
        }
        break;
      }
      if (!name)
        throw new TypeError("Missing parameter name at ".concat(i));
      tokens.push({ type: "NAME", index: i, value: name });
      i = j;
      continue;
    }
    if (char === "(") {
      var count3 = 1;
      var pattern = "";
      var j = i + 1;
      if (str[j] === "?") {
        throw new TypeError('Pattern cannot start with "?" at '.concat(j));
      }
      while (j < str.length) {
        if (str[j] === "\\") {
          pattern += str[j++] + str[j++];
          continue;
        }
        if (str[j] === ")") {
          count3--;
          if (count3 === 0) {
            j++;
            break;
          }
        } else if (str[j] === "(") {
          count3++;
          if (str[j + 1] !== "?") {
            throw new TypeError("Capturing groups are not allowed at ".concat(j));
          }
        }
        pattern += str[j++];
      }
      if (count3)
        throw new TypeError("Unbalanced pattern at ".concat(i));
      if (!pattern)
        throw new TypeError("Missing pattern at ".concat(i));
      tokens.push({ type: "PATTERN", index: i, value: pattern });
      i = j;
      continue;
    }
    tokens.push({ type: "CHAR", index: i, value: str[i++] });
  }
  tokens.push({ type: "END", index: i, value: "" });
  return tokens;
}
__name(lexer, "lexer");
function parse(str, options) {
  if (options === void 0) {
    options = {};
  }
  var tokens = lexer(str);
  var _a = options.prefixes, prefixes = _a === void 0 ? "./" : _a, _b = options.delimiter, delimiter = _b === void 0 ? "/#?" : _b;
  var result = [];
  var key = 0;
  var i = 0;
  var path = "";
  var tryConsume = /* @__PURE__ */ __name(function(type) {
    if (i < tokens.length && tokens[i].type === type)
      return tokens[i++].value;
  }, "tryConsume");
  var mustConsume = /* @__PURE__ */ __name(function(type) {
    var value2 = tryConsume(type);
    if (value2 !== void 0)
      return value2;
    var _a2 = tokens[i], nextType = _a2.type, index = _a2.index;
    throw new TypeError("Unexpected ".concat(nextType, " at ").concat(index, ", expected ").concat(type));
  }, "mustConsume");
  var consumeText = /* @__PURE__ */ __name(function() {
    var result2 = "";
    var value2;
    while (value2 = tryConsume("CHAR") || tryConsume("ESCAPED_CHAR")) {
      result2 += value2;
    }
    return result2;
  }, "consumeText");
  var isSafe = /* @__PURE__ */ __name(function(value2) {
    for (var _i = 0, delimiter_1 = delimiter; _i < delimiter_1.length; _i++) {
      var char2 = delimiter_1[_i];
      if (value2.indexOf(char2) > -1)
        return true;
    }
    return false;
  }, "isSafe");
  var safePattern = /* @__PURE__ */ __name(function(prefix2) {
    var prev = result[result.length - 1];
    var prevText = prefix2 || (prev && typeof prev === "string" ? prev : "");
    if (prev && !prevText) {
      throw new TypeError('Must have text between two parameters, missing text after "'.concat(prev.name, '"'));
    }
    if (!prevText || isSafe(prevText))
      return "[^".concat(escapeString(delimiter), "]+?");
    return "(?:(?!".concat(escapeString(prevText), ")[^").concat(escapeString(delimiter), "])+?");
  }, "safePattern");
  while (i < tokens.length) {
    var char = tryConsume("CHAR");
    var name = tryConsume("NAME");
    var pattern = tryConsume("PATTERN");
    if (name || pattern) {
      var prefix = char || "";
      if (prefixes.indexOf(prefix) === -1) {
        path += prefix;
        prefix = "";
      }
      if (path) {
        result.push(path);
        path = "";
      }
      result.push({
        name: name || key++,
        prefix,
        suffix: "",
        pattern: pattern || safePattern(prefix),
        modifier: tryConsume("MODIFIER") || ""
      });
      continue;
    }
    var value = char || tryConsume("ESCAPED_CHAR");
    if (value) {
      path += value;
      continue;
    }
    if (path) {
      result.push(path);
      path = "";
    }
    var open = tryConsume("OPEN");
    if (open) {
      var prefix = consumeText();
      var name_1 = tryConsume("NAME") || "";
      var pattern_1 = tryConsume("PATTERN") || "";
      var suffix = consumeText();
      mustConsume("CLOSE");
      result.push({
        name: name_1 || (pattern_1 ? key++ : ""),
        pattern: name_1 && !pattern_1 ? safePattern(prefix) : pattern_1,
        prefix,
        suffix,
        modifier: tryConsume("MODIFIER") || ""
      });
      continue;
    }
    mustConsume("END");
  }
  return result;
}
__name(parse, "parse");
function match(str, options) {
  var keys = [];
  var re = pathToRegexp(str, keys, options);
  return regexpToFunction(re, keys, options);
}
__name(match, "match");
function regexpToFunction(re, keys, options) {
  if (options === void 0) {
    options = {};
  }
  var _a = options.decode, decode = _a === void 0 ? function(x) {
    return x;
  } : _a;
  return function(pathname) {
    var m = re.exec(pathname);
    if (!m)
      return false;
    var path = m[0], index = m.index;
    var params = /* @__PURE__ */ Object.create(null);
    var _loop_1 = /* @__PURE__ */ __name(function(i2) {
      if (m[i2] === void 0)
        return "continue";
      var key = keys[i2 - 1];
      if (key.modifier === "*" || key.modifier === "+") {
        params[key.name] = m[i2].split(key.prefix + key.suffix).map(function(value) {
          return decode(value, key);
        });
      } else {
        params[key.name] = decode(m[i2], key);
      }
    }, "_loop_1");
    for (var i = 1; i < m.length; i++) {
      _loop_1(i);
    }
    return { path, index, params };
  };
}
__name(regexpToFunction, "regexpToFunction");
function escapeString(str) {
  return str.replace(/([.+*?=^!:${}()[\]|/\\])/g, "\\$1");
}
__name(escapeString, "escapeString");
function flags(options) {
  return options && options.sensitive ? "" : "i";
}
__name(flags, "flags");
function regexpToRegexp(path, keys) {
  if (!keys)
    return path;
  var groupsRegex = /\((?:\?<(.*?)>)?(?!\?)/g;
  var index = 0;
  var execResult = groupsRegex.exec(path.source);
  while (execResult) {
    keys.push({
      // Use parenthesized substring match if available, index otherwise
      name: execResult[1] || index++,
      prefix: "",
      suffix: "",
      modifier: "",
      pattern: ""
    });
    execResult = groupsRegex.exec(path.source);
  }
  return path;
}
__name(regexpToRegexp, "regexpToRegexp");
function arrayToRegexp(paths, keys, options) {
  var parts = paths.map(function(path) {
    return pathToRegexp(path, keys, options).source;
  });
  return new RegExp("(?:".concat(parts.join("|"), ")"), flags(options));
}
__name(arrayToRegexp, "arrayToRegexp");
function stringToRegexp(path, keys, options) {
  return tokensToRegexp(parse(path, options), keys, options);
}
__name(stringToRegexp, "stringToRegexp");
function tokensToRegexp(tokens, keys, options) {
  if (options === void 0) {
    options = {};
  }
  var _a = options.strict, strict = _a === void 0 ? false : _a, _b = options.start, start = _b === void 0 ? true : _b, _c = options.end, end = _c === void 0 ? true : _c, _d = options.encode, encode = _d === void 0 ? function(x) {
    return x;
  } : _d, _e = options.delimiter, delimiter = _e === void 0 ? "/#?" : _e, _f = options.endsWith, endsWith = _f === void 0 ? "" : _f;
  var endsWithRe = "[".concat(escapeString(endsWith), "]|$");
  var delimiterRe = "[".concat(escapeString(delimiter), "]");
  var route = start ? "^" : "";
  for (var _i = 0, tokens_1 = tokens; _i < tokens_1.length; _i++) {
    var token = tokens_1[_i];
    if (typeof token === "string") {
      route += escapeString(encode(token));
    } else {
      var prefix = escapeString(encode(token.prefix));
      var suffix = escapeString(encode(token.suffix));
      if (token.pattern) {
        if (keys)
          keys.push(token);
        if (prefix || suffix) {
          if (token.modifier === "+" || token.modifier === "*") {
            var mod = token.modifier === "*" ? "?" : "";
            route += "(?:".concat(prefix, "((?:").concat(token.pattern, ")(?:").concat(suffix).concat(prefix, "(?:").concat(token.pattern, "))*)").concat(suffix, ")").concat(mod);
          } else {
            route += "(?:".concat(prefix, "(").concat(token.pattern, ")").concat(suffix, ")").concat(token.modifier);
          }
        } else {
          if (token.modifier === "+" || token.modifier === "*") {
            throw new TypeError('Can not repeat "'.concat(token.name, '" without a prefix and suffix'));
          }
          route += "(".concat(token.pattern, ")").concat(token.modifier);
        }
      } else {
        route += "(?:".concat(prefix).concat(suffix, ")").concat(token.modifier);
      }
    }
  }
  if (end) {
    if (!strict)
      route += "".concat(delimiterRe, "?");
    route += !options.endsWith ? "$" : "(?=".concat(endsWithRe, ")");
  } else {
    var endToken = tokens[tokens.length - 1];
    var isEndDelimited = typeof endToken === "string" ? delimiterRe.indexOf(endToken[endToken.length - 1]) > -1 : endToken === void 0;
    if (!strict) {
      route += "(?:".concat(delimiterRe, "(?=").concat(endsWithRe, "))?");
    }
    if (!isEndDelimited) {
      route += "(?=".concat(delimiterRe, "|").concat(endsWithRe, ")");
    }
  }
  return new RegExp(route, flags(options));
}
__name(tokensToRegexp, "tokensToRegexp");
function pathToRegexp(path, keys, options) {
  if (path instanceof RegExp)
    return regexpToRegexp(path, keys);
  if (Array.isArray(path))
    return arrayToRegexp(path, keys, options);
  return stringToRegexp(path, keys, options);
}
__name(pathToRegexp, "pathToRegexp");

// C:/Users/baral/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/wrangler/templates/pages-template-worker.ts
var escapeRegex = /[.+?^${}()|[\]\\]/g;
function* executeRequest(request) {
  const requestPath = new URL(request.url).pathname;
  for (const route of [...routes].reverse()) {
    if (route.method && route.method !== request.method) {
      continue;
    }
    const routeMatcher = match(route.routePath.replace(escapeRegex, "\\$&"), {
      end: false
    });
    const mountMatcher = match(route.mountPath.replace(escapeRegex, "\\$&"), {
      end: false
    });
    const matchResult = routeMatcher(requestPath);
    const mountMatchResult = mountMatcher(requestPath);
    if (matchResult && mountMatchResult) {
      for (const handler of route.middlewares.flat()) {
        yield {
          handler,
          params: matchResult.params,
          path: mountMatchResult.path
        };
      }
    }
  }
  for (const route of routes) {
    if (route.method && route.method !== request.method) {
      continue;
    }
    const routeMatcher = match(route.routePath.replace(escapeRegex, "\\$&"), {
      end: true
    });
    const mountMatcher = match(route.mountPath.replace(escapeRegex, "\\$&"), {
      end: false
    });
    const matchResult = routeMatcher(requestPath);
    const mountMatchResult = mountMatcher(requestPath);
    if (matchResult && mountMatchResult && route.modules.length) {
      for (const handler of route.modules.flat()) {
        yield {
          handler,
          params: matchResult.params,
          path: matchResult.path
        };
      }
      break;
    }
  }
}
__name(executeRequest, "executeRequest");
var pages_template_worker_default = {
  async fetch(originalRequest, env2, workerContext) {
    let request = originalRequest;
    const handlerIterator = executeRequest(request);
    let data = {};
    let isFailOpen = false;
    const next = /* @__PURE__ */ __name(async (input, init) => {
      if (input !== void 0) {
        let url = input;
        if (typeof input === "string") {
          url = new URL(input, request.url).toString();
        }
        request = new Request(url, init);
      }
      const result = handlerIterator.next();
      if (result.done === false) {
        const { handler, params, path } = result.value;
        const context2 = {
          request: new Request(request.clone()),
          functionPath: path,
          next,
          params,
          get data() {
            return data;
          },
          set data(value) {
            if (typeof value !== "object" || value === null) {
              throw new Error("context.data must be an object");
            }
            data = value;
          },
          env: env2,
          waitUntil: workerContext.waitUntil.bind(workerContext),
          passThroughOnException: /* @__PURE__ */ __name(() => {
            isFailOpen = true;
          }, "passThroughOnException")
        };
        const response = await handler(context2);
        if (!(response instanceof Response)) {
          throw new Error("Your Pages function should return a Response");
        }
        return cloneResponse(response);
      } else if ("ASSETS") {
        const response = await env2["ASSETS"].fetch(request);
        return cloneResponse(response);
      } else {
        const response = await fetch(request);
        return cloneResponse(response);
      }
    }, "next");
    try {
      return await next();
    } catch (error3) {
      if (isFailOpen) {
        const response = await env2["ASSETS"].fetch(request);
        return cloneResponse(response);
      }
      throw error3;
    }
  }
};
var cloneResponse = /* @__PURE__ */ __name((response) => (
  // https://fetch.spec.whatwg.org/#null-body-status
  new Response(
    [101, 204, 205, 304].includes(response.status) ? null : response.body,
    response
  )
), "cloneResponse");
export {
  pages_template_worker_default as default
};
