const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp, getApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const axios = require("axios");

// 初始化 Firebase Admin
initializeApp();

/**
 * 最終版本的即時訊息推播通知函式
 * - 觸發時機：當聊天室有新訊息建立時
 * - 執行方式：讀取訂單與使用者資料，並透過手動呼叫 FCM v1 REST API 來發送通知
 */
exports.sendChatNotification = onDocumentCreated("chats/{orderId}/messages/{messageId}", async (event) => {
    // 1. 獲取新訊息的資料
    const snap = event.data;
    if (!snap) {
        console.log("事件中沒有資料 (No data associated with the event)");
        return;
    }
    const messageData = snap.data();
    const senderId = messageData.senderId;
    const messageText = messageData.text || "您有一則新訊息";

    // 2. 獲取 orderId
    const orderId = event.params.orderId;

    // 3. 從 Firestore 的 'orders' 集合中，找出接收者的 User ID
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

    // 4. 從 Firestore 的 'users' 集合中，獲取接收者的 FCM Token
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

    // --- 以下為我們驗證成功的「手動呼叫 API」邏輯 ---

    // 5. 獲取 Project ID
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    if (!projectId) {
        console.error("錯誤：無法獲取 Firebase Project ID。");
        return;
    }

    // 6. 獲取 API 驗證用的 Access Token
    let accessToken;
    try {
        accessToken = (await getApp().options.credential.getAccessToken()).access_token;
    } catch (e) {
        console.error("獲取 Access Token 失敗:", e);
        return;
    }

    // 7. 準備推播通知的 Payload
    const fcmPayload = {
        message: {
            token: fcmToken, // 使用從資料庫中讀取到的真實 Token
            notification: {
                title: "您有一則新訊息",
                body: messageText,
            },
            data: {
                type: "chat_message",
                orderId: orderId,
            },
            apns: { // 專門為背景/終止狀態的 iOS 加入音效
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        },
    };

    // 8. 發送 HTTPS 請求
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