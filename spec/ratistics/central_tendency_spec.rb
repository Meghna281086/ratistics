require 'spec_helper'

module Ratistics

  class MeanTester
    attr_reader :data
    def initialize(*args); @data = [args].flatten; end
    def each(&block); @data.each {|item| yield(item) }; end
    def empty?; @data.empty?; end
    def first; @data.first; end
    def size; @data.size; end
    def [](index); @data[index]; end
  end

  describe CentralTendency do

    context '#mean' do

      it 'returns zero for a nil sample' do
        CentralTendency.mean(nil).should eq 0
      end

      it 'returns zero for an empty sample' do
        CentralTendency.mean([].freeze).should eq 0
      end

      it 'calculates the mean of a sample' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13].freeze
        mean = CentralTendency.mean(sample)
        mean.should be_within(0.01).of(15.0)
      end

      it 'calculates the mean using a block' do
        sample = [
          {:count => 13},
          {:count => 18},
          {:count => 13},
          {:count => 14},
          {:count => 13},
          {:count => 16},
          {:count => 14},
          {:count => 21},
          {:count => 13},
        ].freeze

        mean = CentralTendency.mean(sample) {|item| item[:count] }
        mean.should be_within(0.01).of(15.0)
      end

      context 'with ActiveRecord', :ar => true do

        before(:all) { Racer.connect }

        specify { CentralTendency.mean(Racer.all.freeze){|r| r.age }.should be_within(0.01).of(38.440) }

      end

      context 'with Hamster', :hamster => true do

        let(:list) { Hamster.list(13, 18, 13, 14, 13, 16, 14, 21, 13).freeze }
        let(:vector) { Hamster.vector(13, 18, 13, 14, 13, 16, 14, 21, 13).freeze }
        let(:set) { Hamster.set(13, 18, 14, 16, 21).freeze }

        specify { CentralTendency.mean(list).should be_within(0.01).of(15.0) }

        specify { CentralTendency.mean(vector).should be_within(0.01).of(15.0) }

        specify { CentralTendency.mean(set).should be_within(0.01).of(16.4) }
      end
    end

    context '#truncated_mean' do

      it 'returns zero for a nil sample' do
        CentralTendency.truncated_mean(nil, 10).should eq 0
      end

      it 'returns zero for an empty sample' do
        CentralTendency.truncated_mean([].freeze, 10).should eq 0
      end

      it 'raises an exception for truncation equal to or greater than 50%' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        lambda {
          CentralTendency.truncated_mean(sample, 50)
        }.should raise_error ArgumentError
      end

      it 'drops the highest and lowest individual values when the truncation is set to nil' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample)
        mean.should be_within(0.01).of(14.722222222222221)
      end

      it 'returns zero for a sample of less than three when truncation is set to nil' do
        CentralTendency.truncated_mean([1, 2].freeze).should eq 0
      end

      it 'calculates the statistical mean for truncation equal to 0%' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample, 0)
        mean.should be_within(0.01).of(14.85)
      end

      it 'calculates the truncated mean when the truncation can be exact' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample, 10)
        mean.should be_within(0.01).of(14.625)
      end

      it 'it rounds truncation to one decimal place' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample, 10.04)
        mean.should be_within(0.01).of(14.625)
      end

      it 'it accepts truncation as a decimal' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample, 0.10)
        mean.should be_within(0.01).of(14.625)
      end

      it 'calculates the interpolated mean when the truncation cannot be exact' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 11, 19, 19, 17, 16, 13, 12, 12, 12, 20, 11].freeze
        mean = CentralTendency.truncated_mean(sample, 12.5)
        mean.should be_within(0.01).of(14.5625)
      end

      it 'calculates the interpolated mean when the collection does not support #slice' do
        sample = MeanTester.new(11, 11, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 16, 16, 17, 18, 19, 19, 20, 21).freeze
        mean = CentralTendency.truncated_mean(sample, 12.5, :sorted => true)
        mean.should be_within(0.01).of(14.0)
      end

      it 'does not sort a sample that is already sorted' do
        sample = [11, 11, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 16, 16, 17, 18, 19, 19, 20, 21]
        sample.should_not_receive(:sort)
        sample.should_not_receive(:sort_by)
        mean = CentralTendency.truncated_mean(sample, 10, :sorted => true)
      end

      it 'calculates the truncated mean with a block' do
        sample = [
          {:count => 11},
          {:count => 11}, 
          {:count => 12},
          {:count => 12},
          {:count => 12},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 14},
          {:count => 14},
          {:count => 16},
          {:count => 16},
          {:count => 17},
          {:count => 18},
          {:count => 19},
          {:count => 19},
          {:count => 20},
          {:count => 21},
        ].freeze

        mean = CentralTendency.truncated_mean(sample, 10){|item| item[:count]}
        mean.should be_within(0.01).of(14.625)
      end

      it 'calculates the interpolated truncated mean with a block' do
        sample = [
          {:count => 11},
          {:count => 11}, 
          {:count => 12},
          {:count => 12},
          {:count => 12},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 14},
          {:count => 14},
          {:count => 16},
          {:count => 16},
          {:count => 17},
          {:count => 18},
          {:count => 19},
          {:count => 19},
          {:count => 20},
          {:count => 21},
        ].freeze

        mean = CentralTendency.truncated_mean(sample, 12.5){|item| item[:count]}
        mean.should be_within(0.01).of(14.5625)
      end

      it 'does not sort a sample with a block' do
        sample = [
          {:count => 13},
        ]

        sample.should_not_receive(:sort)
        sample.should_not_receive(:sort_by)
        mean = CentralTendency.truncated_mean(sample, 10){|item| item[:count]}
      end

      context 'with Hamster', :hamster => true do

        let(:list) { Hamster.list(11, 11, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 16, 16, 17, 18, 19, 19, 20, 21).freeze }
        let(:vector) { Hamster.vector(11, 11, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 16, 16, 17, 18, 19, 19, 20, 21).freeze }
        let(:set) { Hamster.set(11, 11, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 16, 16, 17, 18, 19, 19, 20, 21).freeze }

        specify { CentralTendency.truncated_mean(list, 10).should be_within(0.01).of(14.625) }

        specify { CentralTendency.truncated_mean(vector, 10, :sorted => true).should be_within(0.01).of(14.625) }

        specify { CentralTendency.truncated_mean(set, 10).should be_within(0.01).of(16.125) }
      end
    end

    context '#midrange' do

      it 'returns zero for a nil sample' do
        CentralTendency.midrange(nil).should eq 0
      end

      it 'returns zero for an empty sample' do
        CentralTendency.midrange([].freeze).should eq 0
      end

      it 'returns the value for a one-element sample' do
        CentralTendency.midrange([10].freeze).should be_within(0.01).of(10.0)
      end

      it 'returns the midrange for a two-element sample' do
        CentralTendency.midrange([5, 15].freeze).should be_within(0.01).of(10.0)
      end

      it 'returns the correct midrange for a multi-element sample' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13].freeze
        midrange = CentralTendency.midrange(sample)
        midrange.should be_within(0.01).of(17.0)
      end

      it 'does not sort a sample that is already sorted' do
        sample = [13, 13, 13, 13, 14, 14, 16, 18, 21]
        sample.should_not_receive(:sort)
        sample.should_not_receive(:sort_by)
        midrange = CentralTendency.midrange(sample, :sorted => true)
      end

      it 'calculates the midrange using a block' do
        sample = [
          {:count => 13},
          {:count => 18},
          {:count => 13},
          {:count => 14},
          {:count => 13},
          {:count => 16},
          {:count => 14},
          {:count => 21},
          {:count => 13},
        ].freeze

        midrange = CentralTendency.midrange(sample){|item| item[:count]}
        midrange.should be_within(0.01).of(17.0)
      end

      context 'with ActiveRecord', :ar => true do

        before(:all) { Racer.connect }

        specify { CentralTendency.midrange(Racer.all.freeze){|r| r.age }.should be_within(0.01).of(40.0) }

      end

      context 'with Hamster', :hamster => true do

        let(:list) { Hamster.list(13, 13, 13, 13, 14, 14, 16, 18, 21).freeze }
        let(:vector) { Hamster.vector(13, 13, 13, 13, 14, 14, 16, 18, 21).freeze }
        let(:set) { Hamster.set(13, 13, 13, 13, 14, 14, 16, 18, 21).freeze }

        specify { CentralTendency.midrange(list).should be_within(0.01).of(17.0) }

        specify { CentralTendency.midrange(vector, :sorted => true).should be_within(0.01).of(17.0) }

        specify { CentralTendency.midrange(set).should be_within(0.01).of(17.0) }
      end
    end

    context '#median' do

      it 'returns zero for a nil sample' do
        CentralTendency.mean(nil).should eq 0
      end

      it 'returns zero for an empty sample' do
        CentralTendency.median([].freeze).should eq 0
      end

      it 'calculates the median of an even-number sample' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13, 0].freeze
        median = CentralTendency.median(sample)
        median.should be_within(0.01).of(13.5)
      end

      it 'calculates the median of an odd-number sample' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13].freeze
        median = CentralTendency.median(sample)
        median.should be_within(0.01).of(14.0)
      end

      it 'does not re-sort a sorted sample' do
        sample = [13, 13, 13, 13, 14, 14, 16, 18, 21]
        sample.should_not_receive(:sort)
        sample.should_not_receive(:sort_by)
        CentralTendency.median(sample, :sorted => true)
      end

      it 'calculates the median for an unsorted sample' do
        sample = [13, 18, 13, 14, 13, 16, 14, 21, 13].freeze
        median = CentralTendency.median(sample, :sorted => false)
        median.should be_within(0.01).of(14.0)
      end

      it 'calculates the median of a sorted odd-number sample using a block' do
        sample = [
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 14},
          {:count => 14},
          {:count => 16},
          {:count => 18},
          {:count => 21},
        ].freeze

        median = CentralTendency.median(sample) {|item| item[:count] }
        median.should be_within(0.01).of(14.0)
      end

      it 'calculates the median of a sorted even-number sample using a block' do
        sample = [
          {:count => 0},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 13},
          {:count => 14},
          {:count => 14},
          {:count => 16},
          {:count => 18},
          {:count => 21},
        ].freeze

        median = CentralTendency.median(sample) {|item| item[:count] }
        median.should be_within(0.01).of(13.5)
      end

      it 'does not attempt to sort when a using a block' do
        sample = [
          {:count => 2},
        ]

        sample.should_not_receive(:sort)
        sample.should_not_receive(:sort_by)

        CentralTendency.median(sample, :sorted => false) {|item| item[:count] }
      end

      context 'with ActiveRecord', :ar => true do

        before(:all) { Racer.connect }

        specify { CentralTendency.median(Racer.all.freeze){|r| r.age }.should be_within(0.01).of(23.0) }

      end

      context 'with Hamster', :hamster => true do

        let(:list) { Hamster.list(13, 18, 13, 14, 13, 16, 14, 21, 13).freeze }
        let(:vector) { Hamster.vector(13, 13, 13, 13, 14, 14, 16, 18, 21).freeze }
        let(:set) { Hamster.set(13, 18, 14, 16, 21).freeze }

        specify { CentralTendency.median(list).should be_within(0.01).of(14.0) }

        specify { CentralTendency.median(vector, :sorted => true).should be_within(0.01).of(14.0) }

        specify { CentralTendency.median(set).should be_within(0.01).of(16.0) }

      end
    end

    context '#mode' do

      it 'returns an empty array for a nil sample' do
        CentralTendency.mode(nil).should eq []
      end

      it 'returns an empty array for an empty sample' do
        CentralTendency.mode([].freeze).should eq []
      end

      it 'returns the element for a one-element sample' do
        sample = [1].freeze
        mode = CentralTendency.mode(sample)
        mode.should eq [1]
      end

      it 'returns an array of one element for single-modal sample' do
        sample = [3, 7, 5, 13, 20, 23, 39, 23, 40, 23, 14, 12, 56, 23, 29].freeze
        mode = CentralTendency.mode(sample)
        mode.should eq [23]
      end

      it 'returns an array of two elements for a bimodal sample' do
        sample = [1, 3, 3, 3, 4, 4, 6, 6, 6, 9].freeze
        mode = CentralTendency.mode(sample)
        mode.count.should eq 2
        mode.should include(3)
        mode.should include(6)
      end

      it 'returns an array with all correct modes for a multi-modal sample' do
        sample = [1, 1, 1, 3, 3, 3, 4, 4, 4, 6, 6, 6, 9].freeze
        mode = CentralTendency.mode(sample)
        mode.count.should eq 4
        mode.should include(1)
        mode.should include(3)
        mode.should include(4)
        mode.should include(6)
      end

      it 'returns an array with every value when all elements are unique' do
        sample = [1, 2, 3, 4, 5].freeze
        mode = CentralTendency.mode(sample)
        mode.count.should eq 5
        mode.should include(1)
        mode.should include(2)
        mode.should include(3)
        mode.should include(4)
        mode.should include(5)
      end

      it 'returns the correct values for a single-element sample with a block' do
        sample = [
          {:count => 1},
        ].freeze

        mode = CentralTendency.mode(sample) {|item| item[:count] }
        mode.should eq [1]
      end

      it 'returns the correct values for a single-modal sample with a block' do
        sample = [
          {:count => 1},
          {:count => 3},
          {:count => 2},
          {:count => 2},
          {:count => 2},
        ].freeze

        mode = CentralTendency.mode(sample) {|item| item[:count] }
        mode.should eq [2]
      end

      it 'returns the correct values for a bimodal sample with a block' do
        sample = [
          {:count => 1},
          {:count => 2},
          {:count => 3},
          {:count => 2},
          {:count => 1},
        ].freeze

        mode = CentralTendency.mode(sample) {|item| item[:count] }
        mode.count.should eq 2
        mode.should include(1)
        mode.should include(2)
      end

      it 'returns the correct values for a multimodal sample with a block' do
        sample = [
          {:count => 0},
          {:count => 1},
          {:count => 2},
          {:count => 3},
          {:count => 4},
          {:count => 1},
          {:count => 2},
          {:count => 3},
          {:count => 4},
          {:count => 5},
        ].freeze

        mode = CentralTendency.mode(sample) {|item| item[:count] }
        mode.count.should eq 4
        mode.should include(1)
        mode.should include(2)
        mode.should include(3)
        mode.should include(4)
      end

      context 'with ActiveRecord', :ar => true do

        before(:all) { Racer.connect }

        specify do
          mode = CentralTendency.mode(Racer.all.freeze){|r| r.age }
          mode.count.should eq 1
          mode.should include(40)
        end

      end

      context 'with Hamster', :hamster => true do

        let(:list) { Hamster.list(13, 18, 13, 14, 13, 16, 14, 21, 13).freeze }
        let(:vector) { Hamster.vector(13, 18, 13, 14, 13, 16, 14, 21, 13).freeze }
        let(:set) { Hamster.set(13, 18, 14, 16, 21).freeze }

        specify { CentralTendency.mode(list).should eq [13] }

        specify { CentralTendency.mode(vector).should eq [13] }

        specify do
          mode = CentralTendency.mode(set)
          mode.count.should eq 5
          mode.should include(16)
          mode.should include(18)
          mode.should include(13)
          mode.should include(14)
          mode.should include(21)
        end

      end

    end

    context 'quartiles' do

      let(:odd_sample) { [73, 75, 80, 84, 90, 92, 93, 94, 96].freeze }
      let(:even_sample) { [1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,4,4,5,6].freeze }

      let(:block_sample) do
        [
          {:count => 73},
          {:count => 75},
          {:count => 80},
          {:count => 84},
          {:count => 90},
          {:count => 92},
          {:count => 93},
          {:count => 94},
          {:count => 96}
        ].freeze
      end

      let(:ar_sample) { Racer.where('age > 0').order('age ASC') }

      context 'first' do

        it 'returns nil for a nil sample' do
          CentralTendency.first_quartile(nil).should be_nil
        end

        it 'returns nil for an empty set' do
          CentralTendency.first_quartile([].freeze).should be_nil
        end

        it 'calculates the rank for an even-numbered sample' do
          CentralTendency.first_quartile(even_sample.freeze).should be_within(0.001).of(2)
        end

        it 'calculates the rank for an odd-numbered sample' do
          CentralTendency.first_quartile(odd_sample.freeze).should be_within(0.001).of(77.5)
        end

        it 'calculates the rank with a block' do
          rank = CentralTendency.first_quartile(block_sample.freeze){|item| item[:count]}
          rank.should be_within(0.001).of(77.5)
        end

        it 'does not re-sort a sorted sample' do
          sample = odd_sample.dup
          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.first_quartile(sample, :sorted => true)
        end

        it 'does not attempt to sort when a using a block' do
          sample = [
            {:count => 22},
            {:count => 40}
          ]

          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.first_quartile(sample){|item| item[:count]}
        end

        specify 'with ActiveRecord', :ar => true do
          Racer.connect
          rank = CentralTendency.first_quartile(ar_sample){|r| r.age}
          rank.should be_within(0.001).of(31.0)
        end

        specify 'with Hamster', :hamster => true do

          sample = Hamster.list(*even_sample).freeze
          CentralTendency.first_quartile(sample).should be_within(0.001).of(2)

          sample = Hamster.list(*odd_sample).freeze
          CentralTendency.first_quartile(sample).should be_within(0.001).of(77.5)
        end
      end

      context 'second' do

        it 'returns nil for a nil sample' do
          CentralTendency.second_quartile(nil).should be_nil
        end

        it 'returns nil for an empty set' do
          CentralTendency.second_quartile([].freeze).should be_nil
        end

        it 'calculates the rank for an even-numbered sample' do
          CentralTendency.second_quartile(even_sample.freeze).should be_within(0.001).of(2)
        end

        it 'calculates the rank for an odd-numbered sample' do
          CentralTendency.second_quartile(odd_sample.freeze).should be_within(0.001).of(90.0)
        end

        it 'calculates the rank with a block' do
          rank = CentralTendency.second_quartile(block_sample.freeze){|item| item[:count]}
          rank.should be_within(0.001).of(90.0)
        end

        it 'does not re-sort a sorted sample' do
          sample = odd_sample.dup
          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.second_quartile(sample, :sorted => true)
        end

        it 'does not attempt to sort when a using a block' do
          sample = [
            {:count => 22},
            {:count => 40}
          ]

          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.second_quartile(sample){|item| item[:count]}
        end

        specify 'with ActiveRecord', :ar => true do
          Racer.connect
          rank = CentralTendency.second_quartile(ar_sample){|r| r.age}
          rank.should be_within(0.001).of(38.0)
        end

        specify 'with Hamster', :hamster => true do

          sample = Hamster.list(*even_sample).freeze
          CentralTendency.second_quartile(sample).should be_within(0.001).of(2)

          sample = Hamster.list(*odd_sample).freeze
          CentralTendency.second_quartile(sample).should be_within(0.001).of(90.0)
        end
      end

      context 'third ' do

        it 'returns nil for a nil sample' do
          CentralTendency.third_quartile(nil).should be_nil
        end

        it 'returns nil for an empty set' do
          CentralTendency.third_quartile([].freeze).should be_nil
        end

        it 'calculates the rank for an even-numbered sample' do
          CentralTendency.third_quartile(even_sample.freeze).should be_within(0.001).of(3)
        end

        it 'calculates the rank for an odd-numbered sample' do
          CentralTendency.third_quartile(odd_sample.freeze).should be_within(0.001).of(93.5)
        end

        it 'calculates the rank with a block' do
          rank = CentralTendency.third_quartile(block_sample.freeze){|item| item[:count]}
          rank.should be_within(0.001).of(93.5)
        end

        it 'does not re-sort a sorted sample' do
          sample = odd_sample.dup
          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.third_quartile(sample, :sorted => true)
        end

        it 'does not attempt to sort when a using a block' do
          sample = [
            {:count => 22},
            {:count => 40}
          ]

          sample.should_not_receive(:sort)
          sample.should_not_receive(:sort_by)
          CentralTendency.third_quartile(sample){|item| item[:count]}
        end

        specify 'with ActiveRecord', :ar => true do
          Racer.connect
          rank = CentralTendency.third_quartile(ar_sample){|r| r.age}
          rank.should be_within(0.001).of(47.0)
        end

        specify 'with Hamster', :hamster => true do

          sample = Hamster.list(*even_sample).freeze
          CentralTendency.third_quartile(sample).should be_within(0.001).of(3)

          sample = Hamster.list(*odd_sample).freeze
          CentralTendency.third_quartile(sample).should be_within(0.001).of(93.5)
        end
      end
    end

  end
end
