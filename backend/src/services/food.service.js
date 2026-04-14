// src/services/food.service.js - UUID EVERYWHERE FIX
import { getPgPool } from '../config/postgres.js';

function getMealPeriod(date = new Date()) {
    const hour = date.getHours();

    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 16) return 'lunch';
    if (hour >= 16 && hour < 19) return 'snack';
    return 'dinner';
}

function normalizeArrayValue(value) {
    if (value === null || value === undefined) return {};
    return value;
}

function mealBoost(food, mealPeriod) {
    const text = `${food.name} ${food.category}`.toLowerCase();

    const mealKeywords = {
        breakfast: [
            ['idli', 3.2],
            ['dosa', 3.2],
            ['poha', 3],
            ['uttapam', 3],
            ['tea', 1.5],
            ['curd', 1.8],
            ['sprouts', 1.8],
        ],
        lunch: [
            ['roti', 2.8],
            ['chapati', 2.8],
            ['dal', 2.5],
            ['rice', 2.4],
            ['rajma', 3.2],
            ['chole', 3.1],
            ['khichdi', 3.2],
            ['paneer', 2.6],
            ['curd', 1.9],
        ],
        snack: [
            ['dhokla', 3.1],
            ['bhel', 2.9],
            ['khakra', 2.8],
            ['sprouts', 2.7],
            ['banana', 1.8],
            ['tea', 1.8],
            ['poha', 1.6],
        ],
        dinner: [
            ['roti', 3],
            ['chapati', 3],
            ['dal', 2.7],
            ['curd', 2.2],
            ['khichdi', 3.1],
            ['paneer', 2.8],
            ['sambar', 2.1],
        ],
    };

    return (mealKeywords[mealPeriod] || []).reduce((score, [keyword, boost]) => {
        return text.includes(keyword) ? score + boost : score;
    }, 0);
}

function getRecommendationReason(food, mealPeriod, historyStats) {
    if (mealBoost(food, mealPeriod) > 0) {
        return `Good for ${mealPeriod}`;
    }

    if ((historyStats?.logCount || 0) > 0) {
        return 'Often logged by you';
    }

    return 'Popular Indian food';
}

function mapFoodRow(row) {
    return {
        id: Number(row.id),
        name: row.name,
        servingSize: row.servingSize,
        servingWeightG: Number(row.servingWeightG ?? 0),
        calories: Number(row.calories ?? 0),
        carbsG: Number(row.carbsG ?? 0),
        sugarG: Number(row.sugarG ?? 0),
        proteinG: Number(row.proteinG ?? 0),
        fatG: Number(row.fatG ?? 0),
        fiberG: Number(row.fiberG ?? 0),
        category: row.category,
        glucoseImpactScore: Number(row.glucoseImpactScore ?? 0),
        glucoseImpactDesc: row.glucoseImpactDesc,
        vitamins: normalizeArrayValue(row.vitamins),
        minerals: normalizeArrayValue(row.minerals),
        recommendationScore: row.recommendationScore === undefined
            ? undefined
            : Number(row.recommendationScore),
        recommendationReason: row.recommendationReason,
        mealPeriod: row.mealPeriod,
    };
}

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
        SELECT
            legacy_id AS id,
            name,
            serving_size AS "servingSize",
            serving_weight_g AS "servingWeightG",
            calories,
            carbs_g AS "carbsG",
            sugar_g AS "sugarG",
            protein_g AS "proteinG",
            fat_g AS "fatG",
            fiber_g AS "fiberG",
            category,
            glucose_impact_score AS "glucoseImpactScore",
            glucose_impact_desc AS "glucoseImpactDesc",
            COALESCE(vitamins, '{}'::jsonb) AS vitamins,
            COALESCE(minerals, '{}'::jsonb) AS minerals
        FROM foods 
        WHERE legacy_id IS NOT NULL
          AND (LOWER(name) LIKE $1 OR LOWER(category) LIKE $1)
        ORDER BY name LIMIT 50
    `, [q]);
    return rows.map(mapFoodRow);
}

export async function getRecommendedFoods(userId, limit = 20, now = new Date()) {
    const pool = getPgPool();
    const mealPeriod = getMealPeriod(now);
    const maxItems = Math.min(Math.max(Number(limit) || 20, 1), 50);

    const [foodsResult, foodHistoryResult, categoryHistoryResult] = await Promise.all([
        pool.query(`
            SELECT
                legacy_id AS id,
                name,
                serving_size AS "servingSize",
                serving_weight_g AS "servingWeightG",
                calories,
                carbs_g AS "carbsG",
                sugar_g AS "sugarG",
                protein_g AS "proteinG",
                fat_g AS "fatG",
                fiber_g AS "fiberG",
                category,
                glucose_impact_score AS "glucoseImpactScore",
                glucose_impact_desc AS "glucoseImpactDesc",
                COALESCE(vitamins, '{}'::jsonb) AS vitamins,
                COALESCE(minerals, '{}'::jsonb) AS minerals
            FROM foods
            WHERE legacy_id IS NOT NULL
            ORDER BY name
        `),
        pool.query(`
            SELECT
                food_id,
                COUNT(*)::int AS log_count,
                COUNT(*) FILTER (WHERE logged_at >= NOW() - INTERVAL '14 days')::int AS recent_count,
                MAX(logged_at) AS last_logged_at
            FROM food_logs
            WHERE user_id = $1
              AND food_id IS NOT NULL
            GROUP BY food_id
        `, [userId]),
        pool.query(`
            SELECT
                f.category,
                COUNT(*)::int AS category_count
            FROM food_logs fl
            JOIN foods f ON f.legacy_id = fl.food_id
            WHERE fl.user_id = $1
              AND fl.food_id IS NOT NULL
            GROUP BY f.category
        `, [userId]),
    ]);

    const foodStatsById = new Map(
        foodHistoryResult.rows.map((row) => [String(row.food_id), row]),
    );
    const categoryStatsByName = new Map(
        categoryHistoryResult.rows.map((row) => [String(row.category).toLowerCase(), row.category_count]),
    );

    const scoredFoods = foodsResult.rows.map((food) => {
        const stats = foodStatsById.get(String(food.id));
        const categoryCount = categoryStatsByName.get(String(food.category).toLowerCase()) || 0;
        const lastLoggedAt = stats?.last_logged_at ? new Date(stats.last_logged_at) : null;
        const daysSinceLast = lastLoggedAt ? (now.getTime() - lastLoggedAt.getTime()) / 86400000 : null;
        const recencyBoost = daysSinceLast === null ? 0 : Math.max(0, 8 - daysSinceLast) * 0.35;

        const score =
            mealBoost(food, mealPeriod) +
            (stats?.log_count || 0) * 0.9 +
            (stats?.recent_count || 0) * 1.3 +
            categoryCount * 0.25 +
            recencyBoost;

        return {
            ...food,
            recommendationScore: Number(score.toFixed(2)),
            recommendationReason: getRecommendationReason(food, mealPeriod, stats),
            mealPeriod,
        };
    });

    return scoredFoods
        .sort((a, b) => b.recommendationScore - a.recommendationScore)
        .slice(0, maxItems)
        .map(mapFoodRow);
}
