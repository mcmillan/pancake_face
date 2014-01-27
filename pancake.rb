require 'bundler'
Bundler.require

module PancakeFace
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

    private

    def top_vertical_skew
      (self.original_height / 3).round
    end

    def bottom_vertical_skew
      (self.original_height / 5).round
    end

    def horizontal_skew
      (self.original_width / 10).round
    end
  end

  class Compositor
    def initialize(source, faces)
      @magick_face = MiniMagick::Image.open(source)
      @pancake     = MiniMagick::Image.open('sources/pancake.jpg')
      
      composite_face(faces.first)
    end

    def composite_face(face)
      @magick_face.crop "#{face.width}x#{face.height}+#{face.coordinates[:top_left][:x]}+#{face.coordinates[:top_left][:y]}"
      @magick_face.scale '50%'
      @magick_face.scale '200%'
      @magick_face.resize "250x250"
      @magick_face.modulate "100,20"
      @magick_face.posterize 15
      # @magick_face.gaussian_blur 10
      @magick_face.vignette "0x10+5+5"
      @magick_face.noise 5   
      @composited = @pancake.composite(@magick_face) do |c|
        c.compose "color-burn"
        c.geometry "+125+290"
      end
    end

    def write(*args)
      @composited.write(*args)
    end
  end

  class Detector
    def initialize(source)
      @cv_face     = OpenCV::CvMat.load(source)
      @detector    = OpenCV::CvHaarClassifierCascade::load(
        File.expand_path(File.dirname(__FILE__) + '/haar/haarcascade_frontalface_default.xml')
      )
    end

    def detect
      faces = []
      @detector.detect_objects(@cv_face) do |region|
        next if [region.width, region.height].min < false_threshold
        faces << Face.new(region)
      end
      faces
    end

    private
    def false_threshold
      [@cv_face.width / 10, @cv_face.height / 10].min
    end
  end

  class Generator
    attr_accessor :filename

    def initialize(source)
      faces     = Detector.new(source).detect
      composite = Compositor.new(source, faces)
      
      self.filename  = "#{SecureRandom.uuid}.jpg"
      composite.write("public/faces/#{self.filename}")
    end
  end
end

get '/' do
  erb :index
end

post '/' do
  face = PancakeFace::Generator.new(params[:image][:tempfile].path)

  redirect "/faces/#{face.filename}"
end