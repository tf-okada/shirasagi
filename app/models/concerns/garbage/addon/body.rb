module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :remark, type: String
      field :kana, type: String
      embeds_ids :categories, class_name: "Garbage::Node::Category"

      permit_params :name, :remark, :kana
      permit_params category_ids: []

      template_variable_handler(:remark, :template_variable_handler_name)
      template_variable_handler(:kana, :template_variable_handler_name)
      template_variable_handler(:categories, :template_variable_handler_categories)

      liquidize do
        export :remark
        export :kana
        export as: :categories do
          categories.and_public.order_by(order: 1, name: 1)
        end
      end
    end

    def template_variable_handler_categories(name, issuer)
      ERB::Util.html_escape self.categories.map(&:name).join("\n")
    end
  end
end
