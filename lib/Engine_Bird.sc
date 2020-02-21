// Birds
// Heavily, heavily lifted from https://sccode.org/1-5cy
Engine_Bird : CroneEngine {
  var pg;
  var amp = 0.2;
  var attack = 0.01;
  var release = 0.4;
  var pw = 0.0;
  var gain = 2;
  var pan = 0;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    pg = ParGroup.tail(context.xg);
    SynthDef(\Bird,{
      arg out, freq = 440, pw=pw, amp=amp, attack=attack, gain=gain, release=release, pan=pan;
      var trig = Dust.ar(0.1);
      var env = EnvGen.ar(Env.perc(attack, release, amp, -8), trig, doneAction: 2);
      var sig = SinOsc.ar(freq, pw, env);
      sig = Pan2.ar(sig, pan);
      Out.ar(out, sig);
    }).add;

		this.addCommand("hz", "f", { arg msg;
			var val = msg[1];
      Synth.new(\Bird, [
        \out, context.out_b,
        \freq, val,
        \pw, pw,
        \amp, amp,
        \attack, attack,
        \gain, gain,
        \release, release,
        \pan, pan],
      target:pg);
		});

		this.addCommand("amp", "f", { arg msg;
			amp = msg[1];
		});

		this.addCommand("pw", "f", { arg msg;
			pw = msg[1];
		});

		this.addCommand("attack", "f", { arg msg;
			attack = msg[1];
		});

		this.addCommand("release", "f", { arg msg;
			release = msg[1];
		});

		this.addCommand("gain", "f", { arg msg;
			gain = msg[1];
		});

		this.addCommand("pan", "f", { arg msg;
		  postln("pan: " ++ msg[1]);
			pan = msg[1];
		});
  }

}
