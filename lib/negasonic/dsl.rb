module Negasonic
  module DSL
    def part(instrument:, &block)
      the_instrument = Negasonic::Instrument.find(instrument)

      the_loop = Negasonic::LoopedEvent::Part.new(the_instrument.input_node)
      the_loop.instance_eval(&block)
      the_loop.start
    end

    def pattern(instrument:, type:, notes:)
      the_instrument = Negasonic::Instrument.find(instrument)

      Negasonic::LoopedEvent::Pattern.new(the_instrument.input_node, notes)
                                     .start(type)
    end

    def with_instrument(name, synth:, volume: nil, fx: Negasonic::Instrument::EffectsSet.new, &block)
      fx_set = if fx.is_a?(Negasonic::Instrument::EffectsSet)
                 fx
               else
                 Negasonic::Instrument::EffectsSet.create_from_array(Array(fx))
               end
      synth_node = Negasonic::Instrument::Synth.send(synth, { volume: volume })
      instrument = Negasonic::Instrument.find(name) ||
                   Negasonic::Instrument.add(name)

      old_cycles = instrument.cycles
      instrument.reload

      instrument.base_input_node = synth_node
      instrument.instance_eval(&block) if block_given?

      if instrument.effects_changed?(fx_set)
        fx_set.chain
      end

      Negasonic.schedule_next_cycle do
        if instrument.effects_changed?(fx_set)
          instrument.swap_effects(fx_set)
        end
        instrument.connect_input_nodes_to_effects
        old_cycles.each(&:dispose)
        instrument.cycles.each(&:start)
      end
    end

    def fx(&block)
      Negasonic::Instrument::EffectsSet.new.tap do |fx_set|
        fx_set.instance_eval(&block)
      end
    end
  end
end
