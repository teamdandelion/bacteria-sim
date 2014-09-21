// Generated by CoffeeScript 1.7.1
(function() {
  var Frontend, Renderer, WAIT_FACTOR, processingSetup;

  WAIT_FACTOR = 1.1;

  Renderer = (function() {
    function Renderer(frontend, p) {
      this.frontend = frontend;
      this.p = p;
      this.frames = 0;
      this.frameRate = this.frontend.C.FRAME_RATE;
      this.framesUntilUpdate = 1;
      this.colors = {};
      this.futureColors = {};
      this.currentState = {};
      this.futureState = {};
      this.delta = {};
      this.updateAvailable = false;
      this.update = [];
      this.thunks = 0;
      this.requestUpdate();
      this.lastFrame = Date.now();
      this.removedLastStep = [];
    }

    Renderer.prototype.step = function() {
      var currentTime;
      this.frames++;
      currentTime = Date.now();
      this.lastFrame = currentTime;
      if (this.framesUntilUpdate === 0) {
        if (this.updateAvailable) {
          if (this.thunks > 0) {
            WAIT_FACTOR += .05;
            WAIT_FACTOR *= 1.05;
            console.log("Thunked " + this.thunks + " times");
            this.thunks = 0;
          }
          this.processUpdate();
        } else {
          this.thunks++;
        }
      }
      if (!this.thunks) {
        return this.drawAll();
      }
    };

    Renderer.prototype.drawBlob = function(state, color) {
      var blu, grn, r, red, x, y;
      x = state[0], y = state[1], r = state[2];
      red = color[0], grn = color[1], blu = color[2];
      this.p.noStroke();
      this.p.fill(red, grn, blu);
      return this.p.ellipse(x, y, 2 * r, 2 * r);
    };

    Renderer.prototype.drawAll = function() {
      var id, state, _ref;
      this.p.background(0, 40, 0);
      _ref = this.currentState;
      for (id in _ref) {
        state = _ref[id];
        state[0] += this.delta[id][0];
        state[1] += this.delta[id][1];
        state[2] += this.delta[id][2];
        this.drawBlob(state, this.colors[id]);
      }
      return --this.framesUntilUpdate;
    };

    Renderer.prototype.requestUpdate = function() {
      this.requestTime = Date.now();
      return this.frontend.requestUpdate();
    };

    Renderer.prototype.receiveUpdate = function(update) {
      this.update = update;
      this.timeElapsed = Date.now() - this.requestTime;
      return this.updateAvailable = true;
    };

    Renderer.prototype.processUpdate = function() {
      var addedBlobs, c, dr, dx, dy, id, rc, removedBlobs, rf, xc, xf, yc, yf, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
      this.updateAvailable = false;
      this.requestUpdate();
      this.currentState = this.futureState;
      this.futureState = this.update.blobs;
      removedBlobs = this.update.removed;
      addedBlobs = this.update.added;
      for (id in addedBlobs) {
        c = addedBlobs[id];
        this.colors[id] = c;
      }
      _ref = this.removedLastStep;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        id = _ref[_i];
        delete this.colors[id];
      }
      this.framesUntilUpdate = Math.ceil(WAIT_FACTOR * this.timeElapsed / this.frameRate);
      if (this.framesUntilUpdate < 4) {
        this.framesUntilUpdate = 4;
      }
      _ref1 = this.futureState;
      for (id in _ref1) {
        _ref2 = _ref1[id], xf = _ref2[0], yf = _ref2[1], rf = _ref2[2];
        if (!(id in this.currentState)) {
          this.currentState[id] = [xf, yf, 0];
        }
        _ref3 = this.currentState[id], xc = _ref3[0], yc = _ref3[1], rc = _ref3[2];
        dx = (xf - xc) / this.framesUntilUpdate;
        dy = (yf - yc) / this.framesUntilUpdate;
        dr = (rf - rc) / this.framesUntilUpdate;
        this.delta[id] = [dx, dy, dr];
      }
      for (_j = 0, _len1 = removedBlobs.length; _j < _len1; _j++) {
        id = removedBlobs[_j];
        if (id in this.currentState) {
          dr = -this.currentState[id][2] / this.framesUntilUpdate;
          this.delta[id] = [0, 0, dr];
        } else {
          console.log("blob " + id + " was listed as removed but not found in state");
        }
      }
      return this.removedLastStep = removedBlobs;
    };

    return Renderer;

  })();

  Frontend = (function() {
    function Frontend(p, guiSettings, nonGuiSettings) {
      var d, k, v, _ref, _ref1;
      this.p = p;
      this.guiSettings = guiSettings;
      this.nonGuiSettings = nonGuiSettings;
      this.running = true;
      this.sim = new Worker('web/simulation.js');
      this.sim.onmessage = (function(_this) {
        return function(event) {
          switch (event.data.type) {
            case 'blobs':
              return _this.renderer.receiveUpdate(event.data);
            case 'debug':
              return console.log(event.data.msg);
          }
        };
      })(this);
      this.C = {};
      _ref = this.nonGuiSettings;
      for (k in _ref) {
        v = _ref[k];
        this.C[k] = v;
      }
      _ref1 = this.guiSettings;
      for (k in _ref1) {
        d = _ref1[k];
        this.C[k] = d.value;
      }
      this.C.X_BOUND = $(window).width();
      this.C.Y_BOUND = $(window).height();
      this.updateConstants();
      this.setupGui();
      this.addBlobs(this.C.STARTING_BLOBS);
      this.renderer = new Renderer(this, this.p);
      this.running = true;
      $(window).resize((function(_this) {
        return function() {
          console.log("Resizing");
          _this.C.X_BOUND = $(window).width();
          _this.C.Y_BOUND = $(window).height();
          _this.p.size(_this.C.X_BOUND, _this.C.Y_BOUND);
          return _this.updateConstants();
        };
      })(this));
    }

    Frontend.prototype.updateConstants = function() {
      console.log("Called update constants");
      return this.sim.postMessage({
        type: 'updateConstants',
        data: this.C
      });
    };

    Frontend.prototype.setupGui = function() {
      var gui, opt, vals, varName, _ref;
      opt = {};
      opt['Kill all blobs'] = (function(_this) {
        return function() {
          return _this.sim.postMessage({
            type: 'killAllBlobs'
          });
        };
      })(this);
      opt['Kill most blobs'] = (function(_this) {
        return function() {
          return _this.sim.postMessage({
            type: 'killMostBlobs'
          });
        };
      })(this);
      opt['Add 50 blobs'] = (function(_this) {
        return function() {
          return _this.sim.postMessage({
            type: 'addBlobs',
            data: 50
          });
        };
      })(this);
      opt['Randomize environment'] = (function(_this) {
        return function() {
          var max, min, valueDict, varName, _ref;
          _ref = _this.guiSettings;
          for (varName in _ref) {
            valueDict = _ref[varName];
            min = valueDict.minValue;
            max = valueDict.maxValue;
            _this.C[varName] = min + Math.random() * (max - min);
            if (valueDict.valueType === "Integer") {
              _this.C[varName] = Math.round(_this.C[varName]);
            }
          }
          return _this.updateConstants();
        };
      })(this);
      opt['Shift environment'] = (function(_this) {
        return function() {
          var max, min, movement, valueDict, varName, _ref;
          _ref = _this.guiSettings;
          for (varName in _ref) {
            valueDict = _ref[varName];
            min = valueDict.minValue;
            max = valueDict.maxValue;
            movement = (max - min) * .05 * (Math.random() * 2 - 1);
            _this.C[varName] += movement;
            if (_this.C[varName] < min) {
              _this.C[varName] = min;
            }
            if (_this.C[varName] > max) {
              _this.C[varName] = max;
            }
            if (valueDict.valueType === "Integer") {
              _this.C[varName] = Math.round(_this.C[varName]);
            }
          }
          return _this.updateConstants();
        };
      })(this);
      gui = new dat.GUI();
      _ref = this.guiSettings;
      for (varName in _ref) {
        vals = _ref[varName];
        if (vals.valueType === "Number") {
          gui.add(this.C, varName).min(vals.minValue).max(vals.maxValue).listen().onFinishChange((function(_this) {
            return function() {
              return _this.updateConstants();
            };
          })(this));
        }
        if (vals.valueType === "Integer") {
          gui.add(this.C, varName).min(vals.minValue).max(vals.maxValue).step(1).listen().onFinishChange((function(_this) {
            return function() {
              return _this.updateConstants();
            };
          })(this));
        }
      }
      gui.add(opt, 'Kill all blobs');
      gui.add(opt, 'Add 50 blobs');
      gui.add(opt, 'Kill most blobs');
      gui.add(opt, 'Randomize environment');
      gui.add(opt, 'Shift environment');
      this.showNucleus = false;
      this.showShells = false;
      return this.showReproduction = false;
    };

    Frontend.prototype.step = function() {
      if (this.running) {
        return this.renderer.step();
      }
    };

    Frontend.prototype.requestUpdate = function() {
      return this.sim.postMessage({
        type: 'go'
      });
    };

    Frontend.prototype.addBlobs = function(n) {
      return this.sim.postMessage({
        type: 'addBlobs',
        data: n
      });
    };

    Frontend.prototype.keyCode = function(k) {
      if (k === 32) {
        this.running = !this.running;
      }
      if (k === 78) {
        this.showNucleus = !this.showNucleus;
      }
      if (k === 83) {
        this.showShells = !this.showShells;
      }
      if (k === 82) {
        return this.showReproduction = !this.showReproduction;
      }
    };

    return Frontend;

  })();

  processingSetup = function(p) {
    var frontend;
    frontend = new Frontend(p, window.HACKHACK.guiSettings, window.HACKHACK.nonGuiSettings);
    p.mouseClicked = function() {
      return frontend.mouseClick(p.mouseX, p.mouseY);
    };
    p.setup = function() {
      p.frameRate(frontend.C.FRAME_RATE);
      p.size(frontend.C.X_BOUND, frontend.C.Y_BOUND);
      return p.background(0, 20, 90);
    };
    p.draw = function() {
      return frontend.step();
    };
    return p.keyPressed = function() {
      console.log(p.keyCode);
      return frontend.keyCode(p.keyCode);
    };
  };

  $(document).ready(function() {
    var canvas;
    canvas = $("#processing")[0];
    window.HACKHACK = {};
    window.HACKHACK.tryContinue = function() {
      var processing;
      if ((window.HACKHACK.guiSettings != null) && (window.HACKHACK.nonGuiSettings != null)) {
        processing = new Processing(canvas, processingSetup);
        return window.HACKHACK = null;
      }
    };
    $.getJSON("settings/gui_settings.json", (function(_this) {
      return function(j) {
        window.HACKHACK.guiSettings = j;
        return window.HACKHACK.tryContinue();
      };
    })(this));
    return $.getJSON("settings/non_gui_settings.json", (function(_this) {
      return function(j) {
        window.HACKHACK.nonGuiSettings = j;
        return window.HACKHACK.tryContinue();
      };
    })(this));
  });

}).call(this);
