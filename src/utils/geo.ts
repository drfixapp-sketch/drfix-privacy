/**
 * Utility to determine the currency based on coordinates.
 * Jordan bounds: Lat [29.18, 33.37], Lng [34.95, 39.30] => JOD
 * Saudi/GCC bounds: Lat [15.45, 32.15], Lng [34.50, 60.00] => SAR
 */
export async function getCurrencyBasedOnLocation(isRtl: boolean): Promise<{ currency: string; locationName: string }> {
  const defaultCurrency = isRtl ? 'ريال سعودي' : 'SAR';
  const defaultLocationName = isRtl ? 'الخليج العربي (افتراضي)' : 'Arabian Gulf (Default)';

  if (!navigator.geolocation) {
    return { currency: defaultCurrency, locationName: defaultLocationName };
  }

  return new Promise((resolve) => {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;

        // Jordan bounds check
        if (latitude >= 29.18 && latitude <= 33.37 && longitude >= 34.95 && longitude <= 39.30) {
          resolve({
            currency: isRtl ? 'دينار أردني' : 'JOD',
            locationName: isRtl ? 'عمان، الأردن 🇯🇴' : 'Amman, Jordan 🇯🇴'
          });
        }
        // Saudi / GCC bounds check
        else if (latitude >= 15.45 && latitude <= 32.15 && longitude >= 34.50 && longitude <= 60.00) {
          resolve({
            currency: isRtl ? 'ريال سعودي' : 'SAR',
            locationName: isRtl ? 'الرياض، المملكة العربية السعودية 🇸🇦' : 'Riyadh, Saudi Arabia 🇸🇦'
          });
        }
        else {
          resolve({
            currency: isRtl ? 'دولار أمريكي' : 'USD',
            locationName: isRtl ? 'دولي 🌐' : 'International 🌐'
          });
        }
      },
      () => {
        // Fallback on permission denial or error
        resolve({ currency: defaultCurrency, locationName: defaultLocationName });
      },
      { timeout: 5000, enableHighAccuracy: false }
    );
  });
}
