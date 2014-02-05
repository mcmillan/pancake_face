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
    def initialize(source, faces, id)
      @id     = id
      @source = source
      composite_face(faces.first)
    end

    def composite_face(face)
      @face      = face
      @mask_path = File.expand_path("#{File.dirname(__FILE__)}/tmp/masks/#{@id}.tif")

      begin
        build_mask

        # # Vignette
        # Cocaine::CommandLine.new('mogrify', %q[
        #   -background black -vignette 30x65000 \
        #   :file
        # ].strip).run(
        #   file: @mask_path
        # )

        # Composite
        Cocaine::CommandLine.new('convert', %q[
          sources/pancake.jpg \
          sources/burn.jpg \
          \( -background black -blur 0x1 -noise 0x3 -splice 128x80+0+0 :mask \) \
          -composite :out
        ].strip).run(
          mask: @mask_path,
          out: "public/faces/#{@id}.jpg"
        )
      rescue => e
        raise e
      ensure
        # FileUtils.rm_rf(@mask_path)
      end
    end

    def build_mask
      threshold = 60
      while !analyse_mask
        puts threshold
        create_mask(threshold)
        threshold -= 5
      end
      puts 'done'
    end

    def create_mask(threshold)
      # Initial conversion
      Cocaine::CommandLine.new('convert', %q[
        :in \
        -crop :crop -threshold :threshold% -colors 2 -colorspace gray -normalize -negate -resize 400x400 \
        :out
      ].strip).run(
        crop: "#{@face.width}x#{@face.height}+#{@face.coordinates[:top_left][:x]}+#{@face.coordinates[:top_left][:y]}",
        in: @source,
        out: @mask_path,
        threshold: threshold.to_s
      )
    end

    def analyse_mask
      return false unless File.exists?(@mask_path)

      histogram = Colorscore::Histogram.new(@mask_path)
      palette   = Colorscore::Palette.from_hex(['ffffff', '000000'])
      scores    = palette.scores(histogram.scores, 1)

      puts scores

      scores.first[1].html != '#ffffff'
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
    attr_accessor :id

    def initialize(source)
      @id       = SecureRandom.uuid
      faces     = Detector.new(source).detect
      composite = Compositor.new(source, faces, @id)
    end
  end
end

set :server, :puma

get '/' do
  erb :index
end

post '/' do
  face = PancakeFace::Generator.new(params[:image][:tempfile].path)

  redirect "/faces/#{face.id}.jpg"
end