# Use builtin Image Events app in Mac OS X to resize images with Ruby
# Usage: 
# require 'image_resizer'
# class Foo
#   include ImageResizer
#   def some_method
#     resize('/absolute/path/to/an/image.jpg')
#     resize('/absolute/path/to/an/image.jpg', :target_width => 500)
#   end
# end

module ImageResizer
  def resize(image, options = {})
    options = {:target_width => 100}.merge(options)
    resizer =<<-EOS
#!/bin/sh
osascript <<EOF
tell application "Image Events"
	launch
	set the target_width to #{ options[:target_width] }
	-- open the image file
	set the image_name to "#{ image }"
	set this_image to open image_name

	set typ to this_image's file type

	copy dimensions of this_image to {current_width, current_height}
	if current_width is greater than current_height then
		scale this_image to size target_width
	else
		-- figure out new height
		-- y2 = (y1 * x2) / x1
		set the new_height to (current_height * target_width) / current_width
		scale this_image to size new_height
	end if

	save this_image in image_name as typ
end tell
EOF
    EOS
    system(resizer)
  end
end