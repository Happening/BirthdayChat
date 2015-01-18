Db = require 'db'
Event = require 'event'
Photo = require 'photo'
Plugin = require 'plugin'
Subscription = require 'subscription'
{tr} = require 'i18n'

exports.client_chat = (text,userId) !->
	post userId, {text}, text

exports.onPhoto = (info,userId) !->
	userId = null if userId is true
	post userId, {photo: info.key}, tr("(photo)")

post = (userId, msg, eventText) !->
	if userId
		Plugin.assertAdmin()
		Event.create
			unit: 'msg'
			text: eventText
			for: [userId]
	else
		userId = Plugin.userId()
		Event.create
			unit: 'msg'
			text: "#{Plugin.userName()}: #{eventText}"
			for: ['admin']
	
	msg.time = Math.floor(Date.now()/1000)
	msg.by = Plugin.userId()

	personalO = Db.personal(userId)
	writeMsg personalO, msg

	if (adminStore = Db.admin.ref(userId)) and adminStore.isHash()
		writeMsg adminStore, msg
	else
		log 'copy into admin-store from=', userId
		data = personalO.get()
		data.name = Plugin.userName(userId)
		Db.admin.set userId, data

writeMsg = (store,msg) !->
	id = store.modify 'maxId', (v) -> (v||0)+1
	store.set 0|id/100, id%100, msg

exports.client_discard = (otherId) !->
	Plugin.assertAdmin()
	Db.admin.remove otherId

