require 'bundler'
Bundler.require
Cocaine::CommandLine.path = '/usr/local/bin'

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
    def initialize(source, face, id)
      @id        = id
      @source    = source
      @face      = face
      @mask_path = File.expand_path("#{File.dirname(__FILE__)}/tmp/masks/#{@id}.jpg")

      composite_face
    end

    def composite_face
      begin
        build_mask

        # Vignette
        Cocaine::CommandLine.new('mogrify', %q[
          -background black -vignette 30x65000 \
          :file
        ].strip).run(
          file: @mask_path
        )

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
      ensure
        FileUtils.rm_rf(@mask_path)
      end
    end

    def build_mask
      threshold = 60
      while !analyse_mask && threshold > 10
        create_mask(threshold)
        threshold -= 5
      end
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
end

Instagram.configure do |config|
  config.client_id = "e65a6bc14e3d4b48a0c153b05cd6ea9e"
  config.client_secret = "827840be7b7e44c1849c4e1bb5bd1a65"
end

set :server, :puma
enable :sessions

get '/' do
  erb :index
end

post '/detect' do
  image_id           = session[:image_id] || SecureRandom.uuid
  session[:image_id] = image_id
  path               = File.expand_path("#{File.dirname(__FILE__)}/tmp/uploads/#{image_id}")
  public_path        = File.expand_path("#{File.dirname(__FILE__)}/public/uploads/#{image_id}.jpg")

  case params[:type]
  when 'facebook', 'instagram'
    Cocaine::CommandLine.new('wget', '-O :out :in').run(out: path, in: params[:url])
  when 'webcam'
    url = Base64.decode64(params[:url].split('data:image/png;base64,').last)
    File.open(path, 'wb') { |f| f.write(url) }
  when 'computer'
    File.open(path, 'wb') { |f| f.write(params[:file][:tempfile].read)}
  end

  begin
    Cocaine::CommandLine.new('convert', ':in :out').run(in: path, out: public_path)
  ensure
    FileUtils.rm_rf(path)
  end

  faces = Pancaker::Detector.new(public_path).detect

  session[:faces] = faces

  content_type :json
  { faces: faces, url: url("/uploads/#{image_id}.jpg") }.to_json
end

post '/generate' do
  image_id = session[:image_id]
  face_id  = params[:id].to_i
  face     = session[:faces][face_id]
  source   = File.expand_path("#{File.dirname(__FILE__)}/public/uploads/#{image_id}.jpg")

  composite = Pancaker::Compositor.new(source, face, image_id)

  content_type :json
  { file: "/faces/#{image_id}.jpg" }.to_json
end

get '/auth/instagram' do
  redirect Instagram.authorize_url(redirect_uri: url('/auth/instagram/callback'))
end

get '/auth/instagram/callback' do
  code_response = Instagram.get_access_token(params[:code], redirect_uri: url('/auth/instagram/callback'))
  client        = Instagram.client(access_token: code_response.access_token)
  media         = client.user_recent_media.map { |m| m['images']['standard_resolution']['url'] }

  "<script>window.opener.InstagramPicker.renderGrid(#{media.to_json}); window.close();</script>"
end

get '/tests' do
  erb :fixtures
end

get '/tests/:filename' do
  image_id = SecureRandom.uuid
  source   = File.expand_path("#{File.dirname(__FILE__)}/public/fixtures/#{params[:filename]}")

  face      = Pancaker::Detector.new(source).detect.first
  composite = Pancaker::Compositor.new(source, face, image_id)

  redirect "/faces/#{image_id}.jpg"
end