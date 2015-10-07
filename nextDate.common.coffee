# DatePicker = require 'datepicker'

exports.nd = (day, dayOffset = 0, currentDateOffset = -3) ->
	aDay = 864e5
	halfDay = aDay/2
	date = new Date(day*aDay + halfDay)
	if dayOffset > 0
		dayOffset =  aDay * dayOffset
		date = new Date(date.getTime() - dayOffset)
	now = new Date()
	y = now.getFullYear()-1
	cutOffTime = now.getTime() + currentDateOffset*aDay + halfDay
	loop
		date.setFullYear y++
		break if date.getTime() > cutOffTime
	0|(date.getTime() / aDay)
