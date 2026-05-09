const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Auto-send notifications from queue
exports.sendNotificationQueue = functions.firestore
    .document('schools/{schoolId}/notification_queue/{queueId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const { token, title, body, type, customData } = data;

        if (!token) return;

        const message = {
            token: token,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: type,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                ...(customData || {}),
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    priority: 'high',
                },
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
            },
            webpush: {
                headers: {
                    'Urgency': 'high',
                },
                notification: {
                    icon: '/icons/Icon-192.png',
                    badge: '/icons/Icon-192.png',
                },
            },
        };

        try {
            await admin.messaging().send(message);
            await snap.ref.update({
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log('✅ Notification sent to:', token);
        } catch (error) {
            console.error('❌ Error sending notification:', error);
            await snap.ref.update({
                status: 'failed',
                error: error.message,
                failedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });

// Schedule cleanup of old notifications (runs daily)
exports.cleanupOldNotifications = functions.pubsub
    .schedule('0 0 * * *')
    .onRun(async (context) => {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const oldQueue = await admin.firestore()
            .collectionGroup('notification_queue')
            .where('createdAt', '<', thirtyDaysAgo)
            .get();

        const batch = admin.firestore().batch();
        oldQueue.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        console.log(`🧹 Cleaned up ${oldQueue.size} old notifications`);
    });