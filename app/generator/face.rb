module Pancaker
  class Face
    attr_accessor :original_width, :original_height, :coordinates

    def initialize(region)
      self.original_width  = region.width
      self.original_height = region.height
      self.coordinates     = {
        top_left: {
          x: region.top_left.x - horizontal_skew,
          y: region.top_left.y - top_vertical_skew
        },
        bottom_right: {
          x: region.bottom_right.x + horizontal_skew,
          y: region.bottom_right.y + bottom_vertical_skew
        }
      }
    end

    def width
      self.coordinates[:bottom_right][:x] - self.coordinates[:top_left][:x]
    end

    def height
      self.coordinates[:bottom_right][:y] - self.coordinates[:top_left][:y]
    end

    def to_json(*args)
      { width: width, height: height, coordinates: coordinates }.to_json(*args)
    end

    private

    def top_vertical_skew
      (self.original_height / 1.5).round
    end

    def bottom_vertical_skew
      (self.original_height / 4).round
    end

    def horizontal_skew
      (self.original_width / 7).round
    end
  end
end