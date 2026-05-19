#include <stdio.h>

// حالة السرعة
static int speedEnabled = 1;

// تشغيل/إيقاف السرعة
void SetSpeedEnabled(int enabled) {
    speedEnabled = enabled;
}

int IsSpeedEnabled() {
    return speedEnabled;
}

// مضاعف السرعة
double GetSpeedMultiplier() {
    if (speedEnabled) {
        return 2.0;
    }
    return 1.0;
}

// تسريع الانميشن
double BoostAnimation(double duration) {
    if (speedEnabled) {
        return duration * 0.5;
    }
    return duration;
}