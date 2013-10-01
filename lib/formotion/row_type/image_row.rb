motion_require 'base'

module Formotion
  module RowType
    class ImageRow < Base
      TAKE = BW.localized_string("Take", nil)
      DELETE = BW.localized_string("Delete", nil)
      CHOOSE = BW.localized_string("Choose", nil)
      CANCEL = BW.localized_string("Cancel", nil)

      include BW::KVO

      ##################################
      # 10/1/13 ksi
      attr_accessor :changed
      ##################################

      IMAGE_VIEW_TAG=1100

      ##################################
      # 10/1/13 ksi
      def changed?
        @changed
      end
      ##################################

      def build_cell(cell)
        ##################################
        # 10/1/13 ksi
        @changed = false
        ##################################

        cell.selectionStyle = self.row.selection_style || UITableViewCellSelectionStyleBlue
        # only show the "plus" when editable
        add_plus_accessory(cell) if row.editable?

        observe(self.row, "value") do |old_value, new_value|
          ##################################
          # 10/1/13 ksi
          #### @image_view.image = new_value
          ##################################
          @image_view.image = new_value unless new_value.class.to_s == "String"

          if new_value
            self.row.row_height = 200
            cell.accessoryView = cell.editingAccessoryView = nil
          else
            self.row.row_height = 44
            # only show the "plus" when editable
            add_plus_accessory(cell) if row.editable?
          end
          row.form.reload_data
        end

        @image_view = UIImageView.alloc.init
        @image_view.image = row.value if row.value
        @image_view.tag = IMAGE_VIEW_TAG
        @image_view.contentMode = UIViewContentModeScaleAspectFit
        @image_view.backgroundColor = UIColor.clearColor
        cell.addSubview(@image_view)

        cell.swizzle(:layoutSubviews) do
          def layoutSubviews
            old_layoutSubviews

            # viewWithTag is terrible, but I think it's ok to use here...
            formotion_field = self.viewWithTag(IMAGE_VIEW_TAG)

            field_frame = formotion_field.frame
            field_frame.origin.y = 10
            field_frame.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + Formotion::RowType::Base.field_buffer
            field_frame.size.width  = self.frame.size.width - field_frame.origin.x - Formotion::RowType::Base.field_buffer
            field_frame.size.height = self.frame.size.height - Formotion::RowType::Base.field_buffer
            formotion_field.frame = field_frame
          end
        end
      end

      def on_select(tableView, tableViewDelegate)
        if !row.editable?
          return
        end

        ##################################
        # 10/01/13 ksi
        #@action_sheet = UIActionSheet.alloc.init
        #@action_sheet.delegate = self
        # Check the device - will not work on iPad
        if Device.iphone? || !Device.iphone?
          @action_sheet = UIActionSheet.alloc.init
          @action_sheet.delegate = self

          @action_sheet.destructiveButtonIndex = (@action_sheet.addButtonWithTitle "Delete") if row.value
          @action_sheet.addButtonWithTitle "Take" # if BW::Device.camera.front? or BW::Device.camera.rear?
          @action_sheet.addButtonWithTitle "Choose"
          @action_sheet.cancelButtonIndex = (@action_sheet.addButtonWithTitle "Cancel")

          @action_sheet.showInView @image_view
        else
          @image_picker = UIImagePickerController.alloc.init
          @image_picker.delegate = self

          @popover = UIPopoverController.alloc.initWithContentViewController(@image_picker)
          @popover.delegate = self
          @popover.presentPopoverFromRect(@add_button.frame, inView:@image_view, permittedArrowDirections:0, animated:true)
        end

        #@action_sheet.destructiveButtonIndex = (@action_sheet.addButtonWithTitle DELETE) if row.value
        #@action_sheet.addButtonWithTitle TAKE if BW::Device.camera.front? or BW::Device.camera.rear?
        #@action_sheet.addButtonWithTitle CHOOSE
        #@action_sheet.cancelButtonIndex = (@action_sheet.addButtonWithTitle CANCEL)
        #@action_sheet.showInView @image_view
        ##################################
      end

      def imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        @changed = true
        image = info.valueForKey("UIImagePickerControllerOriginalImage")
        row.value = image
        @popover.dismissPopoverAnimated(true)
      end

      def popoverControllerDidDismissPopover( popoverController )
        @popover = nil
      end

      def actionSheet actionSheet, clickedButtonAtIndex: index
        source = nil

        if index == actionSheet.destructiveButtonIndex
          row.value = nil
          return
        end

        case actionSheet.buttonTitleAtIndex(index)
        when TAKE
          source = :camera
        when CHOOSE
          ##################################
          # 10/01/13 ksi
          #source = :photo_library
          if Device.iphone?
            source = :photo_library
          else
            @image_picker = UIImagePickerController.alloc.init
            @image_picker.delegate = self

            @popover = UIPopoverController.alloc.initWithContentViewController(@image_picker)
            @popover.delegate = self
            @popover.presentPopoverFromRect(@add_button.frame, inView:@image_view, permittedArrowDirections:0, animated:true)
          end
          ##################################
        when CANCEL
        else
          p "Unrecognized button title #{actionSheet.buttonTitleAtIndex(index)}"
        end

        if source
          @camera = BW::Device.camera.send((source == :camera) ? :rear : :any)
          @camera.picture(source_type: source, media_types: [:image]) do |result|
            if result[:original_image]
              #-Resize image when requested (no image upscale)
              if result[:original_image].respond_to?(:resize_image_to_size) and row.max_image_size
                result[:original_image]=result[:original_image].resize_image_to_size(row.max_image_size, false)
              end
              ##################################
              # 10/01/13 ksi
              @changed = true
              ##################################
              row.value = result[:original_image]
            end
          end
        end
      end

      def add_plus_accessory(cell)
        @add_button ||= begin
          button = UIButton.buttonWithType(UIButtonTypeContactAdd)
          button.accessibilityLabel = BW.localized_string("add image", nil)
          button.when(UIControlEventTouchUpInside) do
            self._on_select(nil, nil)
          end
          button
        end
        cell.accessoryView = cell.editingAccessoryView = @add_button
      end
    end
  end
end
