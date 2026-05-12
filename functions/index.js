const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Auto-send notifications from queue (v2 syntax)
exports.sendNotificationQueue = onDocumentCreated(
    'schools/{schoolId}/notification_queue/{queueId}',
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) {
            logger.log('No data associated with the event');
            return;
        }

        const data = snapshot.data();
        const { token, title, body, type, customData } = data;

        if (!token) {
            logger.log('No token provided');
            return;
        }

        const message = {
            token: token,
            notification: {
                title: title || 'School Notification',
                body: body || '',
            },
            data: {
                type: type || 'general',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                ...(customData || {}),
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    priority: 'high',
                    channelId: 'school_channel',
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
                    requireInteraction: true,
                },
            },
        };

        try {
            await admin.messaging().send(message);
            await snapshot.ref.update({
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            logger.log('✅ Notification sent to:', token);
        } catch (error) {
            logger.error('❌ Error sending notification:', error);
            await snapshot.ref.update({
                status: 'failed',
                error: error.message,
                failedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    }
);

// Schedule cleanup of old notifications (runs daily at midnight)
exports.cleanupOldNotifications = onSchedule(
    {
        schedule: '0 0 * * *',
        timeZone: 'Asia/Kolkata',
    },
    async (event) => {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        try {
            const oldQueue = await admin.firestore()
                .collectionGroup('notification_queue')
                .where('createdAt', '<', thirtyDaysAgo)
                .get();

            const batch = admin.firestore().batch();
            oldQueue.docs.forEach(doc => batch.delete(doc.ref));
            await batch.commit();

            logger.log(`🧹 Cleaned up ${oldQueue.size} old notifications`);
        } catch (error) {
            logger.error('Error cleaning up notifications:', error);
        }

        return null;
    }
);