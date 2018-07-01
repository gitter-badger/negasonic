require 'negasonic/instrument/effects_set'
require 'negasonic/instrument/synth'
require 'negasonic/dsl'

module Negasonic
  class Instrument
    @all = []

    class << self
      attr_accessor :all

      def find(name)
        @all.find do |instrument|
          instrument.name == name
        end
      end

      def add(name)
        new(name).tap do |instrument|
          @all << instrument
        end
      end
    end

    attr_reader :name, :cycles

    def initialize(name)
      @name = name
      @cycles = []
      @input_nodes = []
      @used_input_nodes = 0

      # extractable code
      @effect_nodes = []
      @effects_set = EffectsSet.new
      # extractable code
    end

    def reload
      @used_input_nodes = 0
      @effects_set.reload
      @cycles = []
    end

    def base_input_node=(new_base_input_node)
      if @base_input_node != new_base_input_node
        @base_input_node = new_base_input_node

        connect_to_effects(@base_input_node, @effect_nodes)
        @input_nodes = [@base_input_node]
      else
        new_base_input_node.dispose
      end
    end

    # extractable code
    def effects_changed?
      @effect_nodes != @effects_set.nodes
    end

    def swap_effects
      old_effect_nodes = @effect_nodes
      new_effect_nodes = @effects_set.nodes

      @effect_nodes = new_effect_nodes

      old_effect_nodes.each(&:dispose)
    end

    def connect_input_nodes_to_effects
      @input_nodes.each do |input_node|
        connect_to_effects(input_node, @effect_nodes)
      end
    end

    def connect_new_effects
      @effects_set.chain
    end

    def connect_to_effects(input, effects)
      if effects.any?
        input.connect(effects.first)
      else
        input.connect_to_master
      end
    end
    # extractable code

    #########
    ## DSL ##
    #########

    # extractable code
    def with_fx(&block)
      @effects_set.reload
      @effects_set.instance_eval(&block)
    end
    # extractable code

    def cycle(&block)
      cycle_input_node =
        if @input_nodes[@used_input_nodes]
          @input_nodes[@used_input_nodes]
        else
          @base_input_node.clone.tap do |node|
            @input_nodes << node
          end
        end

      the_cycle = Negasonic::LoopedEvent::Sequence.new(cycle_input_node)
      the_cycle.instance_eval(&block)
      @used_input_nodes += 1
      @cycles << the_cycle
    end
  end
end
