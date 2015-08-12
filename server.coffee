Db = require 'db'
Event = require 'event'
Plugin = require 'plugin'
{tr} = require 'i18n'

exports.client_chat = (text,aboutId) !->
	post aboutId, {text}, text

exports.onPhoto = (info,aboutId) !->
	post aboutId, {photo: info.key}, tr("(photo)")

post = (aboutId, msg, eventText) !->
	userId = Plugin.userId()
	Event.create
		unit: 'msg'
		text: Plugin.userName(userId)+': '+eventText
		for: ['all', -aboutId]
		read: [userId]

	msg.time = Math.floor(Date.now()/1000)
	msg.by = userId

	store = Db.shared('chats',aboutId)
	id = store.modify 'maxId', (v) -> (v||0)+1
	store.set 0|id/100, id%100, msg

exports.client_read = (aboutId) !->
	Db.personal(Plugin.aboutId()).remove 'unread', aboutId

exports.client_getRead = (aboutId, id, cb) !->
	read = Db.personal(aboutId).get('maxId') - Event.getUnread(aboutId) >= id
	cb.reply read

exports.client_setBirthdate = (bd,who) !->
	who = 0|who
	if !who || (!Plugin.userIsAdmin() && Plugin.ownerId()!=Plugin.userId())
		who = Plugin.userId()
	Db.shared.set 'birthdates', who, bd

