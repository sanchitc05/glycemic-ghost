// src/services/food.service.js - UUID EVERYWHERE FIX
import { getPgPool } from '../config/postgres.js';

export async function logFood(userId, foodData) {
    console.log('🔍 Flutter data:', foodData);

    const pool = getPgPool();
    const {
        name, carbsG, sugarG, proteinG, fatG, fiberG, calories,
        glucoseImpactScore, quantity, foodId, loggedAt = new Date().toISOString()
    } = foodData;

    // ✅ SMART foodId handler: UUID → NULL, INTEGER → INTEGER
    let foodIdInt = null;
    if (typeof foodId === 'string') {
        if (/^\d+$/.test(foodId)) {
            foodIdInt = parseInt(foodId); // "1" → 1 ✅
            console.log('✅ foodId INTEGER:', foodIdInt);
        } else {
            console.log('⚠️ foodId UUID, using NULL:', foodId);
            foodIdInt = null; // UUID → Skip INTEGER column
        }
    } else if (typeof foodId === 'number') {
        foodIdInt = foodId;
        console.log('✅ foodId NUMBER:', foodIdInt);
    }

    const spikeHeight = Math.min(60, carbsG * (glucoseImpactScore / 10) * 1.2 * quantity);

    try {
        // ✅ food_logs - foodIdInt is either INTEGER or NULL
        const foodResult = await pool.query(`
            INSERT INTO food_logs (user_id, food_id, food_name, carbs_g, sugar_g, protein_g, fat_g, fiber_g, calories, glucose_impact_score, quantity, spike_height, logged_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            RETURNING id
        `, [
            userId,
            foodIdInt,        // ✅ NULL or INTEGER
            name, carbsG, sugarG, proteinG, fatG, fiberG, calories,
            glucoseImpactScore, quantity, spikeHeight, loggedAt
        ]);

        const foodLogId = foodResult.rows[0].id;

        // ✅ dexcom_tokens - same foodIdInt logic
        // for (let minute = 0; minute <= 120; minute += 5) {
        const eventTime = new Date(new Date(loggedAt).getTime() + 15 * 60 * 1000);
        //let mgdlOffset = minute <= 45 ? spikeHeight * (minute / 45) : spikeHeight * (1 - (minute - 45) / 75);
        const mgdl = Math.max(110 + spikeHeight + (Math.random() - 0.5) * 5);
        const trendRate = 1.8;
        const trend = 'DoubleUp';

        console.log(
            [
                userId,                                    // $1: uuid
                eventTime.toISOString(),                   // $2: timestamp
                eventTime.toISOString(),                   // $3: timestamp  
                Math.round(mgdl),                          // $4: integer (value)
                Math.round(mgdl),                          // $5: integer (realtime_value)
                Math.round(mgdl),                          // $6: integer (smoothed_value)
                trendRate,                  // $7: numeric (trend_rate)
                'CGM',                                     // $8: text (status)
                trend,   // $9: text (trend)
                'FOOD',                                    // $10: text (event_source)
                foodIdInt,                                 // $11: integer|null (food_id)
                name,                                      // $12: text (food_name)
                12//foodLogId                                  // $13: integer (food_log_id)
            ]
        );

        // ✅ Demo tokens for simulated data
        const demoAccessToken = `demo_at_${foodLogId}_${15}`;
        const demoRefreshToken = `demo_rt_${foodLogId}_${15}`;
        const now = new Date().toISOString();
        const expiresAt = new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString(); // +12hrs

        await pool.query(`
                INSERT INTO dexcom_tokens (
                    user_id, system_time, display_time, value, realtime_value, smoothed_value,
                    trend_rate, status, trend, event_source, food_id, food_name, food_log_id, access_token, refresh_token, created_at, updated_at, expires_at
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
            `, [
            userId,                                    // $1: uuid
            eventTime.toISOString(),                   // $2: timestamp
            eventTime.toISOString(),                   // $3: timestamp  
            Math.round(mgdl),                          // $4: integer (value)
            Math.round(mgdl),                          // $5: integer (realtime_value)
            Math.round(mgdl),                          // $6: integer (smoothed_value)
            trendRate,                  // $7: numeric (trend_rate)
            'CGM',                                     // $8: text (status)
            trend,   // $9: text (trend)
            'FOOD',                                    // $10: text (event_source)
            foodIdInt,                                 // $11: integer|null (food_id)
            name,                                      // $12: text (food_name)
            12,//foodLogId,                                  // $13: integer (food_log_id)
            demoAccessToken,
            demoRefreshToken,
            now,
            now,
            expiresAt
        ]);
        console.log(`✅ FoodLog ${foodLogId} + 25 CGM spikes (foodId: ${foodIdInt ?? 'NULL'})`);
        return { foodLogId, foodId: foodIdInt ?? null, spikeHeight };
    }

    catch (error) {
        console.error('❌ Error:', error.message);
        throw error;

    }
}


export async function searchFoods(query) {
    const pool = getPgPool();
    const q = `%${query.toLowerCase()}%`;
    const { rows } = await pool.query(`
        SELECT id, name, serving_size, calories, carbs_g, category
        FROM foods 
        WHERE LOWER(name) LIKE $1
        ORDER BY name LIMIT 50
    `, [q]);
    return rows;
}
