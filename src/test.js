import { 
  runAllUk, 
  runAllUs, 
  runAllCa, 
  runAllDe, 
  runAllFr 
} from './connectors/index.js';

// Test all country connectors
(async () => {
  try {
    // Test UK connectors
    const ukItems = await runAllUk('laptop');
    console.log('UK:', Array.isArray(ukItems) ? 'OK' : 'MISSING connector', `(${ukItems.length} items)`);
    
    // Test US connectors
    const usItems = await runAllUs('laptop');
    console.log('US:', Array.isArray(usItems) ? 'OK' : 'MISSING connector', `(${usItems.length} items)`);
    
    // Test CA connectors
    const caItems = await runAllCa('laptop');
    console.log('CA:', Array.isArray(caItems) ? 'OK' : 'MISSING connector', `(${caItems.length} items)`);
    
    // Test DE connectors
    const deItems = await runAllDe('laptop');
    console.log('DE:', Array.isArray(deItems) ? 'OK' : 'MISSING connector', `(${deItems.length} items)`);
    
    // Test FR connectors
    const frItems = await runAllFr('laptop');
    console.log('FR:', Array.isArray(frItems) ? 'OK' : 'MISSING connector', `(${frItems.length} items)`);
    
    // Display total number of items
    const totalItems = ukItems.length + usItems.length + caItems.length + deItems.length + frItems.length;
    console.log(`Total items across all markets: ${totalItems}`);
    
  } catch (error) {
    console.error('Test failed:', error.message);
  }
})();