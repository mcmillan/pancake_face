module Pancaker
  class Detector
    def initialize(source)
      @cv_face     = OpenCV::CvMat.load(source)
      @detector    = OpenCV::CvHaarClassifierCascade::load(
        'haar/haarcascade_frontalface_default.xml'
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
      [@cv_face.width / 8, @cv_face.height / 8].min
    end
  end
end