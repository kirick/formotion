# currently supports only one component

module Formotion
  module RowType
    class ZactionPickerRow < StringRow
      include RowType::ItemsMapper

      def after_build(cell)
        self.row.text_field.text = name_for_value(row.value).to_s
        self.row.text_field.enabled = false

        add_plus_accessory(cell)
      end

      def on_select(tableView, tableViewDelegate)
        self.row.text_field.enabled = true
        self.row.text_field.becomeFirstResponder
        self.row.text_field.enabled = false
        on_complete = lambda{ 
          |picker, itemSelected, strSelected| 
          self.row.text_field.text = strSelected
          self.row.text_field.resignFirstResponder
        }

        on_cancel = lambda{
          |picker|
        }

        initialSelection = 0
        if row.value
          if row.items.include?(row.value)
            initialSelection = row.items.index(row.value)
          end
        end
        ActionSheetStringPicker.showPickerWithTitle(row.title, rows:row.items, initialSelection:initialSelection, doneBlock:on_complete, cancelBlock:on_cancel, origin:@add_button)
      end

      def add_plus_accessory(cell)
        @add_button ||= begin
          button = UIButton.buttonWithType(UIButtonTypeContactAdd)
          button.when(UIControlEventTouchUpInside) do
            self.on_select(nil, nil)
          end
          button.hidden = true
          button
        end
        cell.accessoryView = cell.editingAccessoryView = @add_button
      end

      #def row_value
      #  name_for_value(row.value)
      #end
    end
  end
end