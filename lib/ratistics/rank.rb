module Ratistics

  module Rank
    extend self

    # Calculate the set of percentile ranks for every element in the sample.
    #
    # Will sort the data set using natural sort order unless
    # the :sorted option is true or a block is given. when the :flatten
    # option is true duplicate values will be removed from the sample and
    # only the highest percentile for that value will be returned.
    #
    # When a block is given the block will be applied to every
    # element in the data set. Using a block in this way allows
    # probability to be computed against a specific field in a
    # data set of hashes or objects.
    #
    # The return value is an array of arrays. Each element in the outer
    # array represents one value in the sample. Each value will be a
    # two-element array where the first value is the element itself and
    # the second element will be the percentile.
    #
    # @example
    #   [[1, 7.142857142857143],
    #    [3, 21.428571428571427],
    #    [5, 35.714285714285715],
    #    [7, 50.0],
    #    [9, 64.28571428571429],
    #    [9, 78.57142857142857],
    #    [14, 92.85714285714286]]
    #
    # @yield iterates over each element in the data set
    # @yieldparam item each element in the data set
    #
    # @param [Enumerable] data the data set to compute the percentiles for
    # @param [Hash] opts computation options
    # @param [Block] block optional block for per-item processing
    #
    # @option opts [String] :sorted indicates of the data is already sorted
    # @option opts [String] :flatten remove duplicate data values
    #
    # @return [Array] set of values and percentiles
    def percentiles(data, opts={}, &block)
      return [] if data.nil? || data.empty?
      data = data.sort unless block_given? || opts[:sorted] == true

      centiles = []

      data.each_index do |index|

        p = 100.0 * ((index+1).to_f - 0.5) / data.size.to_f

        item = block_given? ? yield(data[index]) : data[index]
        if opts[:flatten] == true && index > 0 && centiles.last[0] == item
          centiles.pop
        end

        centiles << [item, p]
      end

      return centiles
    end

    alias :centiles :percentiles

    ## The value of a variable below which a certain percent of observations fall 
    ## Linear interpolation between closest ranks
    #def percentile(data, percentile, opts={}, &block)
    #end

    #alias :centile :percentile

    #def nearest_rank(data, percentile, opts={}, &block)
    #end

    #def weighted_percentile(data, percentile, opts={}, &block)
    #end

    #def percentile?
    #alias :centile? :percentile?

    ## The percentage of scores in the frequency distribution that are the same or lower
    #def percentile_rank(data, value, sorted=false, opts={}, &block)
    #alias :centile_rank :percentile_rank

    #def percentile_rank?(data, value, percentile, sorted=false, opts={}, &block) 
    #alias :centile_rank? :percentile_rank?

    #def lower_quartile
    #def upper_quartile
    #def first_quartile
    #def second_quartile
    #def third_quartile



  end
end