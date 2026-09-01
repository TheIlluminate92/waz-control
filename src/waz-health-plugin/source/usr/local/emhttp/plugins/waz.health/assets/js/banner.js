(function () {
  "use strict";

  if (window.WAZHealth && window.WAZHealth.version) return;

  var config = window.WAZHealthBootstrap || {};
  var endpoint = config.endpoint || "/plugins/waz.health/include/status.php";
  var fanEndpoint = config.fanEndpoint || "/plugins/waz.health/include/md1200-control.php";
  // Unraid publishes the current session token as a page-global variable.
  var csrfToken = String(window.csrf_token || config.csrfToken || "");
  var refreshMs = Math.max(3000, Number(config.refreshMs) || 5000);
  var allowedStates = ["normal", "attention", "fault", "unknown"];
  var subsystemOrder = ["array", "storage", "cooling", "ups"];
  var state = {
    server: { label: "WAZ-SERVER", uptimeSeconds: null },
    overall: { label: "SYSTEM NORMAL", state: "normal", message: "" },
    subsystems: {},
    fans: { enabled: false, mode: "auto", manualSpeed: 20, healthState: "normal", shelves: [] },
    uptimeSampledAt: Date.now()
  };
  var banner = null;
  var refreshTimer = null;
  var clockTimer = null;
  var resizeObserver = null;
  var fanBusy = false;

  function normalizeState(value) {
    value = String(value || "unknown").toLowerCase();
    return allowedStates.indexOf(value) >= 0 ? value : "unknown";
  }

  function escapeText(value) {
    return String(value == null ? "" : value);
  }

  function formatUptime(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) return "—";
    var totalMinutes = Math.floor(seconds / 60);
    var days = Math.floor(totalMinutes / 1440);
    var hours = Math.floor((totalMinutes % 1440) / 60);
    var minutes = totalMinutes % 60;
    if (days > 0) return days + "d " + hours + "h";
    if (hours > 0) return hours + "h " + minutes + "m";
    return minutes + "m";
  }

  function localTime() {
    return new Intl.DateTimeFormat(undefined, {
      hour: "numeric",
      minute: "2-digit"
    }).format(new Date());
  }

  function createIndicator(key, label) {
    var item = document.createElement("span");
    item.className = "waz-health__subsystem";
    item.dataset.subsystem = key;

    var name = document.createElement("span");
    name.className = "waz-health__subsystem-label";
    name.textContent = label;

    var dot = document.createElement("span");
    dot.className = "waz-health__dot";
    dot.setAttribute("aria-hidden", "true");

    item.appendChild(name);
    item.appendChild(dot);
    return item;
  }

  function openDashboardModules() {
    if (typeof window.contentMgmt === "function") window.contentMgmt();
  }

  function updateDashboardModulesControl() {
    if (!banner) return;
    var control = banner.querySelector(".waz-health__modules");
    if (control) control.hidden = typeof window.contentMgmt !== "function";
  }

  function setFanMode(value) {
    if (fanBusy || !state.fans.enabled) return;
    var manual = value !== "auto";
    var speed = manual ? Number(value) : Number(state.fans.manualSpeed || 20);
    var prompt = manual
      ? "Set both MD1200 shelves to " + speed + "% manual fan speed?"
      : "Return both MD1200 shelves to automatic temperature control?";
    if (!window.confirm(prompt)) {
      renderFans();
      return;
    }

    fanBusy = true;
    renderFans();
    var body = new URLSearchParams();
    body.set("csrf_token", csrfToken);
    body.set("mode", manual ? "manual" : "auto");
    if (manual) body.set("speed", String(speed));
    fetch(fanEndpoint, {
      method: "POST",
      credentials: "same-origin",
      cache: "no-store",
      headers: { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" },
      body: body.toString()
    })
      .then(function (response) {
        return response.json().then(function (payload) {
          if (!response.ok) throw new Error(payload.error || "Fan control update failed");
          state.fans = Object.assign({}, state.fans, payload);
        });
      })
      .catch(function (error) {
        window.alert(error.message || "Fan control update failed");
      })
      .finally(function () {
        fanBusy = false;
        renderFans();
        window.setTimeout(refresh, 1200);
      });
  }

  function createFanControl() {
    var control = document.createElement("span");
    control.className = "waz-health__fans";
    control.dataset.field = "fans";
    control.innerHTML = '<span class="waz-health__fans-label"><span class="waz-health__dot" aria-hidden="true"></span>MD1200</span>' +
      '<span class="waz-health__fan-readings"><span data-fan-shelf="top">TOP —</span><span data-fan-shelf="bottom">BOTTOM —</span></span>';

    var select = document.createElement("select");
    select.className = "waz-health__fan-select";
    select.setAttribute("aria-label", "MD1200 fan control mode and manual speed");
    [
      ["auto", "AUTO"],
      ["20", "MANUAL 20%"],
      ["30", "MANUAL 30%"],
      ["40", "MANUAL 40%"],
      ["50", "MANUAL 50%"]
    ].forEach(function (entry) {
      var option = document.createElement("option");
      option.value = entry[0];
      option.textContent = entry[1];
      select.appendChild(option);
    });
    select.addEventListener("change", function () { setFanMode(select.value); });
    control.appendChild(select);
    return control;
  }

  function createBanner() {
    var root = document.createElement("section");
    root.id = "waz-health-banner";
    root.className = "waz-health";
    root.setAttribute("role", "status");
    root.setAttribute("aria-live", "polite");
    root.setAttribute("aria-label", "WAZ server health");

    var inner = document.createElement("div");
    inner.className = "waz-health__inner";

    var identity = document.createElement("span");
    identity.className = "waz-health__identity";
    identity.dataset.field = "server";

    var overall = document.createElement("span");
    overall.className = "waz-health__overall";
    overall.innerHTML = '<span class="waz-health__dot" aria-hidden="true"></span><span data-field="overall">SYSTEM NORMAL</span>';

    var dividerOne = document.createElement("span");
    dividerOne.className = "waz-health__divider";
    dividerOne.setAttribute("aria-hidden", "true");

    var subsystems = document.createElement("span");
    subsystems.className = "waz-health__subsystems";
    subsystemOrder.forEach(function (key) {
      subsystems.appendChild(createIndicator(key, key.toUpperCase()));
    });

    var dividerTwo = dividerOne.cloneNode(true);

    var fanControl = createFanControl();

    var dividerThree = dividerOne.cloneNode(true);

    var meta = document.createElement("span");
    meta.className = "waz-health__meta";

    var modules = document.createElement("button");
    modules.type = "button";
    modules.className = "waz-health__modules";
    modules.hidden = true;
    modules.title = "Manage dashboard modules";
    modules.setAttribute("aria-label", "Manage dashboard modules");
    var modulesIcon = document.createElement("i");
    modulesIcon.className = "fa fa-fw fa-wrench";
    modulesIcon.setAttribute("aria-hidden", "true");
    modules.appendChild(modulesIcon);
    modules.addEventListener("click", openDashboardModules);

    meta.appendChild(modules);
    meta.insertAdjacentHTML("beforeend", '<time class="waz-health__time" data-field="time"></time><span class="waz-health__uptime"><span aria-hidden="true">↑</span><span data-field="uptime">—</span></span>');

    inner.appendChild(identity);
    inner.appendChild(overall);
    inner.appendChild(dividerOne);
    inner.appendChild(subsystems);
    inner.appendChild(dividerTwo);
    inner.appendChild(fanControl);
    inner.appendChild(dividerThree);
    inner.appendChild(meta);
    root.appendChild(inner);

    var issues = document.createElement("div");
    issues.className = "waz-health__issues";
    issues.dataset.field = "issues";
    issues.setAttribute("aria-label", "Active health details");
    root.appendChild(issues);
    return root;
  }

  function renderIssues() {
    if (!banner) return;
    var issuesNode = banner.querySelector('[data-field="issues"]');
    if (!issuesNode) return;

    var activeIssues = [];
    subsystemOrder.forEach(function (key) {
      var value = state.subsystems[key] || {};
      var issueState = normalizeState(value.state);
      if (issueState !== "attention" && issueState !== "fault") return;
      activeIssues.push({
        label: value.label || key.toUpperCase(),
        state: issueState,
        message: value.message || ((value.label || key.toUpperCase()) + " reported " + issueState)
      });
    });

    var overallState = normalizeState(state.overall.state);
    if (!activeIssues.length && (overallState === "attention" || overallState === "fault")) {
      activeIssues.push({
        label: state.overall.label || "SYSTEM",
        state: overallState,
        message: state.overall.message || "System health requires attention"
      });
    }

    activeIssues.sort(function (left, right) {
      var rank = { fault: 2, attention: 1 };
      return (rank[right.state] || 0) - (rank[left.state] || 0);
    });

    issuesNode.replaceChildren();
    activeIssues.forEach(function (issue) {
      var item = document.createElement("span");
      item.className = "waz-health__issue";
      item.dataset.state = issue.state;

      var dot = document.createElement("span");
      dot.className = "waz-health__dot";
      dot.setAttribute("aria-hidden", "true");

      var label = document.createElement("strong");
      label.textContent = issue.label;

      var message = document.createElement("span");
      message.textContent = issue.message;

      item.appendChild(dot);
      item.appendChild(label);
      item.appendChild(message);
      issuesNode.appendChild(item);
    });

    banner.classList.toggle("waz-health--expanded", activeIssues.length > 0);
  }

  function updateClockAndUptime() {
    if (!banner) return;
    var timeNode = banner.querySelector('[data-field="time"]');
    var uptimeNode = banner.querySelector('[data-field="uptime"]');
    if (timeNode) {
      timeNode.textContent = localTime();
      timeNode.setAttribute("datetime", new Date().toISOString());
    }
    if (uptimeNode) {
      var elapsed = Math.max(0, (Date.now() - state.uptimeSampledAt) / 1000);
      var seconds = Number(state.server.uptimeSeconds);
      uptimeNode.textContent = formatUptime(Number.isFinite(seconds) ? seconds + elapsed : NaN);
    }
  }

  function render() {
    if (!banner) return;
    var serverNode = banner.querySelector('[data-field="server"]');
    var overallNode = banner.querySelector('[data-field="overall"]');
    var overall = banner.querySelector(".waz-health__overall");

    if (serverNode) serverNode.textContent = escapeText(state.server.label || "WAZ-SERVER");
    if (overallNode) overallNode.textContent = escapeText(state.overall.label || "STATUS UNKNOWN");
    if (overall) overall.dataset.state = normalizeState(state.overall.state);

    subsystemOrder.forEach(function (key) {
      var item = banner.querySelector('[data-subsystem="' + key + '"]');
      var value = state.subsystems[key] || { label: key.toUpperCase(), state: "unknown" };
      if (!item) return;
      item.dataset.state = normalizeState(value.state);
      var label = item.querySelector(".waz-health__subsystem-label");
      if (label) label.textContent = escapeText(value.label || key.toUpperCase());
      item.setAttribute("aria-label", (value.label || key) + ": " + normalizeState(value.state));
    });

    renderFans();

    renderIssues();
    updateClockAndUptime();
    updateDashboardModulesControl();
  }

  function renderFans() {
    if (!banner) return;
    var control = banner.querySelector('[data-field="fans"]');
    if (!control) return;
    var fans = state.fans || {};
    var enabled = fans.enabled === true;
    var mode = fans.mode === "manual" ? "manual" : "auto";
    var select = control.querySelector("select");
    var readings = control.querySelector(".waz-health__fan-readings");
    control.dataset.state = enabled ? normalizeState(fans.healthState || "unknown") : "unknown";
    control.classList.toggle("waz-health__fans--disabled", !enabled);
    control.classList.toggle("waz-health__fans--manual", mode === "manual");
    if (select) {
      select.value = mode === "manual" ? String(fans.manualSpeed || 20) : "auto";
      select.disabled = !enabled || fanBusy;
      select.title = enabled ? "Controls both MD1200 shelves" : "Controller is staged but not enabled";
    }
    if (readings) readings.hidden = mode !== "auto";

    ["top", "bottom"].forEach(function (id) {
      var node = control.querySelector('[data-fan-shelf="' + id + '"]');
      if (!node) return;
      var shelf = (fans.shelves || []).find(function (item) { return item.id === id; }) || {};
      var rpm = Number(shelf.averageRpm);
      node.textContent = id.toUpperCase() + " " + (Number.isFinite(rpm) && rpm > 0 ? Math.round(rpm) + " RPM" : "—");
      node.title = [
        shelf.name || ("MD1200 " + id),
        shelf.temperatureC == null ? "temperature unavailable" : shelf.temperatureC + "°C from " + (shelf.temperatureSource || "assigned disks"),
        shelf.targetPercent == null ? "target unavailable" : shelf.targetPercent + "% target",
        shelf.telemetryMessage || "fan telemetry current"
      ].join(" · ");
    });
    control.setAttribute("aria-label", enabled
      ? "MD1200 fan control: " + mode + (mode === "manual" ? " at " + fans.manualSpeed + " percent" : "")
      : "MD1200 fan control is staged but disabled");
  }

  function mergeSnapshot(next) {
    if (!next || typeof next !== "object") return;
    if (next.server && typeof next.server === "object") {
      state.server = Object.assign({}, state.server, next.server);
      if (next.server.uptimeSeconds != null) state.uptimeSampledAt = Date.now();
    }
    if (next.overall && typeof next.overall === "object") {
      state.overall = Object.assign({}, state.overall, next.overall);
    }
    if (next.subsystems && typeof next.subsystems === "object") {
      state.subsystems = Object.assign({}, state.subsystems, next.subsystems);
    }
    if (next.fans && typeof next.fans === "object") {
      state.fans = Object.assign({}, state.fans, next.fans);
    }
    render();
  }

  function refresh() {
    return fetch(endpoint, {
      credentials: "same-origin",
      cache: "no-store",
      headers: { Accept: "application/json" }
    })
      .then(function (response) {
        if (!response.ok) throw new Error("WAZ Health endpoint returned " + response.status);
        return response.json();
      })
      .then(function (snapshot) {
        mergeSnapshot(snapshot);
        if (banner) banner.dataset.connection = "online";
        return snapshot;
      })
      .catch(function (error) {
        if (banner) banner.dataset.connection = "offline";
        if (window.console && console.debug) console.debug("WAZ Health refresh failed", error);
        return null;
      });
  }

  function updateStickyOffset(menu) {
    if (!banner || !menu) return;
    var style = window.getComputedStyle(menu);
    var navIsTopSticky = style.position === "sticky" && document.documentElement.classList.contains("Theme--nav-top");
    banner.style.setProperty("--waz-health-sticky-top", navIsTopSticky ? menu.offsetHeight + "px" : "0px");
  }

  function mount() {
    if (document.getElementById("waz-health-banner")) {
      banner = document.getElementById("waz-health-banner");
      return;
    }

    var menu = document.getElementById("menu");
    var display = document.getElementById("displaybox");
    banner = createBanner();

    if (menu && menu.parentNode) {
      menu.insertAdjacentElement("afterend", banner);
      updateStickyOffset(menu);
      if (window.ResizeObserver) {
        resizeObserver = new ResizeObserver(function () { updateStickyOffset(menu); });
        resizeObserver.observe(menu);
      } else {
        window.addEventListener("resize", function () { updateStickyOffset(menu); });
      }
    } else if (display && display.parentNode) {
      display.parentNode.insertBefore(banner, display);
    } else {
      document.body.insertBefore(banner, document.body.firstChild);
    }

    render();
    refresh();
    refreshTimer = window.setInterval(refresh, refreshMs);
    clockTimer = window.setInterval(updateClockAndUptime, 60000);
  }

  window.WAZHealth = {
    version: "@@APP_VERSION@@",
    refresh: refresh,
    setState: function (next) {
      mergeSnapshot(next);
      return JSON.parse(JSON.stringify(state));
    },
    getState: function () {
      return JSON.parse(JSON.stringify(state));
    },
    destroy: function () {
      if (refreshTimer) window.clearInterval(refreshTimer);
      if (clockTimer) window.clearInterval(clockTimer);
      if (resizeObserver) resizeObserver.disconnect();
      if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
      banner = null;
    }
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mount, { once: true });
  } else {
    mount();
  }
})();
