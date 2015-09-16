# DatePicker = require 'datepicker'

exports.nd = (day, dayOffset = 0) ->
	halfDay = 12*3600*1000
	date = new Date(day*864e5 + halfDay)
	if dayOffset > 0
		dayOffset = (24*3600*1000) * dayOffset
		date = new Date(date.getTime() - dayOffset)
	# date = DatePicker.dayToDate(day)
	now = new Date()
	y = now.getFullYear()-1
	cutOffTime = now.getTime() - 3*24*3600*1000 + halfDay
	loop
		date.setFullYear y++
		break if date.getTime() > cutOffTime
	0|(date.getTime() / 864e5)
