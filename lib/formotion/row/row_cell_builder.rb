#################
#
# Formotion::RowCellBuilder
# RowCellBuilder handles taking Formotion::Rows
# and configuring UITableViewCells based on their properties.
#
#################
module Formotion
  class RowCellBuilder

    # PARAMS row.is_a? Formotion::Row
    # RETURNS [cell configured to that row, a UITextField for that row if applicable or nil]
    def self.make_cell(row)
      cell, text_field = nil

      cell = UITableViewCell.alloc.initWithStyle(row.object.cell_style, reuseIdentifier:row.reuse_identifier)

      cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone
      cell.textLabel.text = row.title
      cell.detailTextLabel.text = row.subtitle

      edit_field = row.object.build_cell(cell)
      
      if edit_field and edit_field.respond_to?("accessibilityLabel=")
        label = row.accessibility
        label = row.title unless label
        edit_field.accessibilityLabel = label if label
      end

      [cell, edit_field]
    end

  end
end