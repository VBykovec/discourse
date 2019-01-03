class ReviewablesController < ApplicationController
  requires_login

  def index
    reviewables = Reviewable.list_for(current_user, status: :pending)

    # This is a bit awkward, but ActiveModel serializers doesn't seem to serialize STI
    hash = {}
    json = {
      reviewables: reviewables.map do |r|
        serializer = serializer_for(r)
        result = serializer.new(r, root: nil, hash: hash, scope: guardian).as_json
        hash[:reviewable_actions].uniq!
        result
      end
    }
    json.merge!(hash)

    render_json_dump(json, rest_serializer: true)
  end

  def perform
    render json: success_json
  end

protected

  def lookup_serializer_for(type)
    "#{type}Serializer".constantize
  rescue NameError
    ReviewableSerializer
  end

  def serializer_for(reviewable)
    type = reviewable.type
    @serializers ||= {}
    @serializers[type] ||= lookup_serializer_for(type)
  end

end
