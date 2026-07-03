/* eslint-disable no-var */
// This file is plain JS (no ERB) so it can be loaded directly in unit tests
// (see spec/javascript) as well as served as-is by the Rails asset pipeline.
//
// Configuration is supplied at runtime via a `window.SessionCheckConfig`
// object assigned by app/views/_session_check.html.erb, e.g.:
//
//   window.SessionCheckConfig = {
//     should_session_check: true,
//     check_every_s: 30,
//     session_time: 3600,
//     logged_out_url: '/users/sign_in',
//     reset_counter_on_ajax: true
//   };
(function (global) {
  'use strict';

  // `createSessionCheck` builds a fresh instance of the session-check
  // behaviour. `deps` allows tests to inject fakes for jQuery, the clock and
  // timer functions instead of relying on browser globals.
  function createSessionCheck(config, deps) {
    config = config || {};
    deps = deps || {};

    var $ = deps.$ || global.$;
    var now = deps.now || function () {
      return Date.now();
    };
    var setTimeoutFn = deps.setTimeout || global.setTimeout;
    var documentRef = deps.document || global.document;
    var locationRef = deps.location || global;

    var check_every_s = config.check_every_s;
    var session_time = config.session_time;
    var check_every_ms = check_every_s * 1000;
    var min_check_interval_ms = 5 * 1000; // don't re-check more than once per 5s
    var session_expires_at = now() + session_time * 1000; // absolute timestamp, not a countdown
    var last_check_at = now();

    var SessionCheck = {
      should_session_check: !!config.should_session_check
    };

    var force_sign_in = function () {
      locationRef.location = config.logged_out_url;
    };

    var check_session_with_server = function () {
      last_check_at = now();
      $.get('/session_check/time_to_session_expiry')
        .done(function (d) {
          if (!d.session_exists) {
            force_sign_in();
          } else {
            session_expires_at = now() + d.session_expires_in * 1000;
          }
        })
        .fail(force_sign_in);
    };

    var session_check = function () {
      if (SessionCheck.should_session_check && now() >= session_expires_at) {
        check_session_with_server();
      }
      setTimeoutFn(session_check, check_every_ms);
    };

    var on_visibility_change = function () {
      if (documentRef.visibilityState === 'visible' && SessionCheck.should_session_check) {
        if (now() - last_check_at > min_check_interval_ms) {
          check_session_with_server();
        }
      }
    };

    var on_ajax_complete = function () {
      session_expires_at = now() + session_time * 1000;
      last_check_at = now();
    };

    var start = function () {
      setTimeoutFn(session_check, check_every_ms);

      // Whenever the tab becomes visible again, go straight to the server
      // for ground truth instead of trusting local timers/clock math.
      // Debounced so rapid tab-switching doesn't spam the endpoint.
      documentRef.addEventListener('visibilitychange', on_visibility_change);

      if (config.reset_counter_on_ajax) {
        $.ajaxSetup({
          complete: on_ajax_complete
        });
      }
    };

    return {
      SessionCheck: SessionCheck,
      start: start,
      // Exposed for unit testing only.
      _internal: {
        force_sign_in: force_sign_in,
        check_session_with_server: check_session_with_server,
        session_check: session_check,
        on_visibility_change: on_visibility_change,
        on_ajax_complete: on_ajax_complete,
        get session_expires_at() {
          return session_expires_at;
        },
        get last_check_at() {
          return last_check_at;
        }
      }
    };
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = createSessionCheck;
  }

  if (typeof global.SessionCheckConfig !== 'undefined') {
    var instance = createSessionCheck(global.SessionCheckConfig);
    global.SessionCheck = instance.SessionCheck;
    instance.start();
  }
})(typeof window !== 'undefined' ? window : this);
