module Negasonic
  module LoopedEvent
    class Sequence
      def initialize(synth, segments = [])
        @synth = synth
        @segments = segments
      end

      def start(duration)
        do_start(duration) do |time, note|
          @synth.trigger_attack_release(note, duration, time)
        end
      end

      def play(*notes)
        @segments << notes
      end

      private

      def do_start(duration, &block)
        LoopedEvent.start(Tone::Event::Sequence.new @segments, duration, &block)
      end
    end
  end
end
