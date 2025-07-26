const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");
const axios = require("axios");

// 初始化 Firebase Admin
admin.initializeApp();

/**
 * 原始的即時訊息推播通知函式
 */
exports.sendChatNotification = onDocumentCreated("chats/{orderId}/messages/{messageId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        console.log("事件中沒有資料 (No data associated with the event)");
        return;
    }
    const messageData = snap.data();
    const senderId = messageData.senderId;
    const messageText = messageData.text || "您有一則新訊息";
    const orderId = event.params.orderId;

    let receiverId;
    try {
        const orderDoc = await getFirestore().collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
            console.log("在 'orders' 集合中找不到訂單:", orderId);
            return;
        }
        const orderData = orderDoc.data();
        const consumerId = orderData.consumerId;
        const storeOwnerId = orderData.storeOwnerId;
        receiverId = senderId === consumerId ? storeOwnerId : consumerId;
    } catch (error) {
        console.error("查詢訂單參與者失敗:", error);
        return;
    }

    if (!receiverId) {
        console.log("無法判斷接收者 ID");
        return;
    }

    const userDoc = await getFirestore().collection("users").doc(receiverId).get();
    if (!userDoc.exists) {
        console.log("在 'users' 集合中找不到接收者使用者文件:", receiverId);
        return;
    }
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
        console.log(`使用者 ${receiverId} 沒有 FCM Token，不發送通知。`);
        return;
    }

    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    if (!projectId) {
        console.error("錯誤：無法獲取 Firebase Project ID。");
        return;
    }

    let accessToken;
    try {
        const app = admin.app();
        accessToken = (await app.options.credential.getAccessToken()).access_token;
    } catch (e) {
        console.error("獲取 Access Token 失敗:", e);
        return;
    }

    const fcmPayload = {
        message: {
            token: fcmToken,
            notification: {
                title: "您有一則新訊息",
                body: messageText,
            },
            data: {
                type: "chat_message",
                orderId: orderId,
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        },
    };

    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    try {
        console.log(`準備發送通知給使用者 ${receiverId} (Token: ${fcmToken.substring(0, 10)}...)`);
        const response = await axios.post(fcmEndpoint, fcmPayload, {
            headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json",
            },
        });
        console.log("通知發送成功！伺服器回應:", response.status);
    } catch (error) {
        console.error("通知 API 呼叫失敗:", error.response ? error.response.data : error.message);
    }
});


/**
 * 新商品上架通知函式 (包含附近使用者通知)
 */
exports.sendNewProductNotification = onDocumentCreated("products/{productId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        console.log("事件中沒有資料");
        return;
    }
    const productData = snap.data();
    const storeId = productData.storeId;
    const productName = productData.name || "新的驚喜";

    if (!storeId) {
        console.log(`商品 ${event.params.productId} 沒有 storeId，無法發送通知。`);
        return;
    }

    const db = getFirestore();
    const storeDoc = await db.collection("stores").doc(storeId).get();
    if (!storeDoc.exists) {
        console.log(`找不到店家 ${storeId} 的資料。`);
        return;
    }
    const storeData = storeDoc.data();
    const storeName = storeData.name || "一家很棒的店";
    const storeLat = storeData.latitude;
    const storeLon = storeData.longitude;

    if (typeof storeLat !== 'number' || typeof storeLon !== 'number') {
        console.log(`店家 ${storeName} 沒有有效的經緯度資訊。`);
        return;
    }

    const userIdsToNotify = new Set();

    const favoritesSnapshot = await db.collection("users").where("favoriteStores", "array-contains", storeId).get();
    favoritesSnapshot.forEach((doc) => {
        userIdsToNotify.add(doc.id);
    });
    console.log(`找到 ${userIdsToNotify.size} 位收藏該店家的使用者。`);

    const radiusKm = 5;
    const latDelta = radiusKm / 111.0;
    const lonDelta = radiusKm / (111.0 * Math.cos(storeLat * Math.PI / 180));

    const minLat = storeLat - latDelta;
    const maxLat = storeLat + latDelta;
    const minLon = storeLon - lonDelta;
    const maxLon = storeLon + lonDelta;

    const nearbyUsersSnapshot = await db.collection("users")
        .where("lastKnownLatitude", ">=", minLat)
        .where("lastKnownLatitude", "<=", maxLat)
        .get();

    let nearbyUserCount = 0;
    nearbyUsersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.lastKnownLongitude >= minLon && userData.lastKnownLongitude <= maxLon) {
            userIdsToNotify.add(doc.id);
            nearbyUserCount++;
        }
    });
    console.log(`在 5 公里範圍內找到 ${nearbyUserCount} 位使用者。`);

    if (userIdsToNotify.size === 0) {
        console.log(`總計 0 位使用者需要被通知。`);
        return;
    }

    const tokens = [];
    const userIdsArray = Array.from(userIdsToNotify);
    for (let i = 0; i < userIdsArray.length; i += 30) {
        const chunk = userIdsArray.slice(i, i + 30);
        const usersSnapshot = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", chunk).get();
        usersSnapshot.forEach((doc) => {
            const userData = doc.data();
            if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        });
    }

    if (tokens.length === 0) {
        console.log("找到了使用者，但他們都沒有 FCM Token。");
        return;
    }

    const payload = {
        notification: {
            title: `🎁 ${storeName} 有新的盲盒上架了！`,
            body: `快來看看「${productName}」吧！`,
        },
        data: {
            type: "new_product_from_favorite",
            storeId: storeId,
        },
    };

    try {
        for (let i = 0; i < tokens.length; i += 500) {
            const chunk = tokens.slice(i, i + 500);
            const multicastMessage = { ...payload, tokens: chunk };
            const response = await getMessaging().sendMulticast(multicastMessage);
            console.log(`成功發送 ${response.successCount} 則通知。`);
            if (response.failureCount > 0) {
                console.log(`有 ${response.failureCount} 則通知發送失敗。`);
            }
        }
    } catch (error) {
        console.error("發送新商品通知時發生錯誤:", error);
    }
});