motion_require 'string_row'

module Formotion
	module RowType
		class ReadonlyRow < StringRow

			#def keyboardType
			#  UIKeyboardTypeEmailAddress
			#end
			def build_cell(cell)
				c = super(cell)
				c.enabled = false
				c
			end
		end
	end
end