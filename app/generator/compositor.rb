module Pancaker
  class Compositor
    def initialize(source, face, pan, threshold_sway = 0)
      @source         = source
      @face           = face
      @pan            = pan
      @threshold_sway = threshold_sway
      @filename       = File.basename(source)

      composite
    end

    def can_lighten?
      @score > 5
    end

    def can_darken?
      @score < 80
    end

    private
    def composite
      begin
        @magick_image = MiniMagick::Image.open(@source)

        generate_crop
        generate_mask

        Cocaine::CommandLine.new('convert', %q[
          :pan \
          :burn \
          \( -background black -blur 0x1 -noise 0x3 -splice 210x50+0+0 :mask \) \
          -composite :out
        ].strip).run(
          mask: "tmp/masks/#{@filename}",
          out: "public/faces/#{@filename}",
          burn: "app/assets/composition/burns/#{@pan}.jpg",
          pan: "app/assets/composition/pans/#{@pan}.jpg"
        )
      ensure
        FileUtils.rm_rf("tmp/crops/#{@filename}", secure: true)
        FileUtils.rm_rf("tmp/samples/#{@filename}", secure: true)
        FileUtils.rm_rf("tmp/masks/#{@filename}", secure: true)
      end
    end

    def generate_crop
      @magick_image.combine_options do |m|
        m.crop "#{@face.width}x#{@face.height}+#{@face.coordinates[:top_left][:x]}+#{@face.coordinates[:top_left][:y]}"
        m.resize "340x340"
        m.colorspace 'Gray'
        m.brightness_contrast "10x10"
      end

      @magick_image.write "tmp/crops/#{@filename}"
    end

    def generate_mask    
      @score = whiteness_score

      @magick_image.threshold "#{@score}%"
      @magick_image.blur "0x1"
      @magick_image.noise "0x3"
      @magick_image.vignette "30x65000"
      @magick_image.negate
      @magick_image.write "tmp/masks/#{@filename}"
    end

    def whiteness_score
      sample = MiniMagick::Image.open("tmp/crops/#{@filename}")
      sample.combine_options do |m|
        m.gravity "center"
        m.crop "50x50+0+0"
        m.repage.+
      end
      sample.write "tmp/samples/#{@filename}"

      # Do whiteness analysis
      histogram = Colorscore::Histogram.new("tmp/samples/#{@filename}")
      palette   = Colorscore::Palette.from_hex(['ffffff'])
      score     = palette.scores(histogram.scores)

      if score.count == 0
        score = 35
      else
        whiteness = score.first.first
        score = (whiteness * 100)
        score += (whiteness > 0.8 ? -5 : [90 - (whiteness * 100).round, 15].min)
      end

      swayed_score = score + @threshold_sway

      swayed_score.between?(0, 100) ? swayed_score : score
    end
  end
end