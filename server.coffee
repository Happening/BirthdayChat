Db = require 'db'
Event = require 'event'
Plugin = require 'plugin'
{tr} = require 'i18n'

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
	log "setting read", aboutId
	# Db.personal(Plugin.aboutId()).remove 'unread', aboutId
	Db.personal(userId).set 'read', null
	Db.personal(userId).set 'read', aboutId, null
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

