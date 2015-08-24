Db = require 'db'
Event = require 'event'
Plugin = require 'plugin'
Timer = require 'timer'
{tr} = require 'i18n'
nextDate = require('nextDate').nd

exports.getTitle = !-> # prevents title input from showing up when adding the p$

exports.client_chat = (text,aboutId) !->
	log 'chat called'
	post aboutId, {text}, text

exports.onPhoto = (info,aboutId) !->
	post aboutId, {photo: info.key}, tr("(photo)")

exports.client_makeDataO = (aboutId) !->
	Db.shared.set('chats', aboutId, 'maxId', 0)

post = (aboutId, msg, eventText) !->
	log 'posting: ' + msg
	userId = Plugin.userId()
	Event.create
		unit: 'msg'
		text: Plugin.userName(userId)+': '+eventText
		exclude: [aboutId]
		read: [userId]

	msg.time = Math.floor(Date.now()/1000)
	msg.by = userId

	if !Db.shared.peek('chats', aboutId)? #not created when bsent
		Db.shared.set('chats', aboutId, null)
	store = Db.shared.ref('chats', aboutId)

	id = store.modify 'maxId', (v) -> (v||0)+1
	store.set 0|id/100, id%100, msg

exports.client_read = (aboutId) !->
	userId = Plugin.userId()
	# Db.personal(Plugin.aboutId()).remove 'unread', aboutId
	# Db.personal(userId).set 'read', null
	# Db.personal(userId).set 'read', aboutId, null
	Db.personal(userId).set 'read', aboutId, Db.shared.peek('chats', aboutId, 'maxId')|0
	log "read:", Db.personal(userId).peek('read', aboutId)

exports.client_getRead = (aboutId, id, cb) !->
	read = Db.personal(aboutId).get('maxId') - Event.getUnread(aboutId) >= id
	cb.reply read

exports.client_setBirthdate = (bd, who) !->
	who = 0|who
	if !who || ((!Plugin.userIsAdmin() && Plugin.ownerId()!=Plugin.userId()) && Db.shared.peek('birthdates', who))
		who = Plugin.userId()
	Db.shared.set 'birthdates', who, bd
	updateTime()

exports.client_update = !->
	updateTime()

# Master server
exports.onBirthdayTimer = !->
	log "RING RING! Someones birthday is in 10 days!"
	aboutId = Db.shared.get('timer', 'id')
	Event.create
		unit: 'announcement'
		text: tr("%1's birthday is in 10 days!", Plugin.userName(aboutId))
		# path: [6]
		exclude: [aboutId]
		# read: [userId]
	updateTime() #and do the timer again.

updateTime = !->
	duration = 1000
	firstDate = 100000
	firstId = 0
	#for dates
	Db.shared.iterate 'birthdates', (bde) !->
		#check which is the first
		bd = bde.get()
		nd = nextDate(bd, 10)
		log bd, "-", nd
		if  nd > 0 and nd < firstDate
			firstId = bde.key()
			firstDate = nextDate(bd, 10)
			log "firstdate", firstDate
	#set new timer
	firstDate = new Date(firstDate*864e5)
	firstDate.setHours(10)
	duration = firstDate.getTime() - Plugin.time()*1000

	log tr("setting timer to %1 (%2)", new Date(firstDate), duration)
	#write to db
	Db.shared.set 'timer',
		'id': parseInt firstId
		'time': firstDate.getTime()

	#cancel and redo
	Timer.cancel('onBirthdayTimer')
	Timer.set(duration, 'onBirthdayTimer')

	# exports.onBirthdayTimer()