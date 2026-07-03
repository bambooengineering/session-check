'use strict';

const createSessionCheck = require('../../app/assets/javascripts/session_check');

function buildDeferred() {
  const deferred = {};
  deferred.promise = {
    done(fn) {
      deferred._done = fn;
      return deferred.promise;
    },
    fail(fn) {
      deferred._fail = fn;
      return deferred.promise;
    }
  };
  deferred.resolve = (data) => deferred._done && deferred._done(data);
  deferred.reject = () => deferred._fail && deferred._fail();
  return deferred;
}

function buildDeps(overrides) {
  const timeouts = [];
  const documentStub = {
    visibilityState: 'visible',
    _listeners: {},
    addEventListener(event, handler) {
      this._listeners[event] = handler;
    },
    fireVisibilityChange() {
      this._listeners.visibilitychange && this._listeners.visibilitychange();
    }
  };

  const deps = {
    now: jest.fn(() => 0),
    setTimeout: jest.fn((fn) => {
      timeouts.push(fn);
      return timeouts.length;
    }),
    document: documentStub,
    location: {},
    $: {
      get: jest.fn(),
      ajaxSetup: jest.fn()
    }
  };

  return Object.assign(deps, { timeouts }, overrides);
}

function baseConfig(overrides) {
  return Object.assign(
    {
      should_session_check: true,
      check_every_s: 30,
      session_time: 3600,
      logged_out_url: '/users/sign_in',
      reset_counter_on_ajax: false
    },
    overrides
  );
}

describe('session_check', () => {
  test('exposes SessionCheck.should_session_check from config', () => {
    const deps = buildDeps();
    const instance = createSessionCheck(baseConfig({ should_session_check: false }), deps);

    expect(instance.SessionCheck.should_session_check).toBe(false);
  });

  test('does not ping the server before the session is due to expire', () => {
    const deps = buildDeps();
    deps.now.mockReturnValue(0);

    const instance = createSessionCheck(baseConfig({ session_time: 3600 }), deps);
    instance.start();

    // Session expires at t=3,600,000ms; we're still at t=0.
    deps.timeouts[0]();

    expect(deps.$.get).not.toHaveBeenCalled();
  });

  test('pings the server once the session is due to expire', () => {
    const deps = buildDeps();
    deps.now.mockReturnValue(0);
    const deferred = buildDeferred();
    deps.$.get.mockReturnValue(deferred.promise);

    const instance = createSessionCheck(baseConfig({ session_time: 10 }), deps);
    instance.start();

    deps.now.mockReturnValue(20 * 1000); // past the 10s session_time
    deps.timeouts[0]();

    expect(deps.$.get).toHaveBeenCalledWith('/session_check/time_to_session_expiry');
  });

  test('redirects to logged_out_url when the server reports no session', () => {
    const deps = buildDeps();
    deps.now.mockReturnValue(0);
    const deferred = buildDeferred();
    deps.$.get.mockReturnValue(deferred.promise);

    const instance = createSessionCheck(baseConfig({ session_time: 10, logged_out_url: '/login' }), deps);
    instance.start();

    deps.now.mockReturnValue(20 * 1000);
    deps.timeouts[0]();
    deferred.resolve({ session_exists: false });

    expect(deps.location.location).toBe('/login');
  });

  test('redirects to logged_out_url when the server request fails', () => {
    const deps = buildDeps();
    deps.now.mockReturnValue(0);
    const deferred = buildDeferred();
    deps.$.get.mockReturnValue(deferred.promise);

    const instance = createSessionCheck(baseConfig({ session_time: 10, logged_out_url: '/login' }), deps);
    instance.start();

    deps.now.mockReturnValue(20 * 1000);
    deps.timeouts[0]();
    deferred.reject();

    expect(deps.location.location).toBe('/login');
  });

  test('updates session_expires_at from the server response instead of redirecting', () => {
    const deps = buildDeps();
    deps.now.mockReturnValue(0);
    const deferred = buildDeferred();
    deps.$.get.mockReturnValue(deferred.promise);

    const instance = createSessionCheck(baseConfig({ session_time: 10 }), deps);
    instance.start();

    deps.now.mockReturnValue(20 * 1000);
    deps.timeouts[0]();
    deferred.resolve({ session_exists: true, session_expires_in: 60 });

    expect(deps.location.location).toBeUndefined();
    expect(instance._internal.session_expires_at).toBe(20 * 1000 + 60 * 1000);
  });

  test('re-schedules the poll loop on every tick', () => {
    const deps = buildDeps();
    const instance = createSessionCheck(baseConfig(), deps);
    instance.start();

    expect(deps.setTimeout).toHaveBeenCalledTimes(1);
    deps.timeouts[0]();
    expect(deps.setTimeout).toHaveBeenCalledTimes(2);
  });

  describe('visibilitychange debounce', () => {
    test('checks the server when the tab becomes visible after the debounce window', () => {
      const deps = buildDeps();
      deps.now.mockReturnValue(0);
      const deferred = buildDeferred();
      deps.$.get.mockReturnValue(deferred.promise);

      const instance = createSessionCheck(baseConfig(), deps);
      instance.start();

      deps.now.mockReturnValue(6 * 1000); // > 5s min_check_interval_ms
      deps.document.fireVisibilityChange();

      expect(deps.$.get).toHaveBeenCalledWith('/session_check/time_to_session_expiry');
    });

    test('does not check the server again within the debounce window', () => {
      const deps = buildDeps();
      deps.now.mockReturnValue(0);
      deps.$.get.mockReturnValue(buildDeferred().promise);

      const instance = createSessionCheck(baseConfig(), deps);
      instance.start();

      deps.now.mockReturnValue(2 * 1000); // < 5s min_check_interval_ms
      deps.document.fireVisibilityChange();

      expect(deps.$.get).not.toHaveBeenCalled();
    });

    test('does nothing when should_session_check is false', () => {
      const deps = buildDeps();
      deps.now.mockReturnValue(0);

      const instance = createSessionCheck(baseConfig({ should_session_check: false }), deps);
      instance.start();

      deps.now.mockReturnValue(6 * 1000);
      deps.document.fireVisibilityChange();

      expect(deps.$.get).not.toHaveBeenCalled();
    });
  });

  describe('ajaxSetup counter reset', () => {
    test('registers an ajaxSetup complete handler when reset_counter_on_ajax is enabled', () => {
      const deps = buildDeps();
      const instance = createSessionCheck(baseConfig({ reset_counter_on_ajax: true }), deps);
      instance.start();

      expect(deps.$.ajaxSetup).toHaveBeenCalledWith({ complete: expect.any(Function) });
    });

    test('does not register an ajaxSetup handler when reset_counter_on_ajax is disabled', () => {
      const deps = buildDeps();
      const instance = createSessionCheck(baseConfig({ reset_counter_on_ajax: false }), deps);
      instance.start();

      expect(deps.$.ajaxSetup).not.toHaveBeenCalled();
    });

    test('resets session_expires_at and last_check_at on ajax completion', () => {
      const deps = buildDeps();
      deps.now.mockReturnValue(0);

      const instance = createSessionCheck(baseConfig({ session_time: 10, reset_counter_on_ajax: true }), deps);
      instance.start();

      deps.now.mockReturnValue(8 * 1000);
      const { complete } = deps.$.ajaxSetup.mock.calls[0][0];
      complete();

      expect(instance._internal.session_expires_at).toBe(8 * 1000 + 10 * 1000);
      expect(instance._internal.last_check_at).toBe(8 * 1000);
    });
  });
});
