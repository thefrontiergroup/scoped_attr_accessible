module CustomMatchers
  class OnlyHaveAttributesMatcher

    def initialize(*attrs)
      @attributes = attrs.map(&:to_s)
    end

    def matches?(target)
      @target_attributes = target.keys.map(&:to_s)
      (@target_attributes & @attributes) == @target_attributes
    end

    def failure_message_for_should
      "expected to only allow attributes #{@attributes.join(", ")}, allowed #{@target_attributes.join(", ")}"
    end

    def failure_message_for_should_not
      "expected to not only allow attributes #{@attributes.join(", ")}, allowed #{@target_attributes.join(", ")}"
    end

  end

  def only_have_attributes(*attrs)
    OnlyHaveAttributesMatcher.new(*attrs)
  end
end