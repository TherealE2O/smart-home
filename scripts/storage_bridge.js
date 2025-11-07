// JavaScript bridge for LocalStorage access from Godot
// This file should be included in the HTML export template

var GodotStorage = {
    // Save data to localStorage
    saveData: function(key, value) {
        try {
            localStorage.setItem(UTF8ToString(key), UTF8ToString(value));
            return 1; // Success
        } catch (e) {
            console.error("Failed to save to localStorage:", e);
            return 0; // Failure
        }
    },
    
    // Load data from localStorage
    loadData: function(key) {
        try {
            var value = localStorage.getItem(UTF8ToString(key));
            if (value === null) {
                return 0; // Key not found
            }
            // Allocate memory for the string and return pointer
            var bufferSize = lengthBytesUTF8(value) + 1;
            var buffer = _malloc(bufferSize);
            stringToUTF8(value, buffer, bufferSize);
            return buffer;
        } catch (e) {
            console.error("Failed to load from localStorage:", e);
            return 0; // Failure
        }
    },
    
    // Remove data from localStorage
    removeData: function(key) {
        try {
            localStorage.removeItem(UTF8ToString(key));
            return 1; // Success
        } catch (e) {
            console.error("Failed to remove from localStorage:", e);
            return 0; // Failure
        }
    },
    
    // Clear all localStorage
    clearAll: function() {
        try {
            localStorage.clear();
            return 1; // Success
        } catch (e) {
            console.error("Failed to clear localStorage:", e);
            return 0; // Failure
        }
    },
    
    // Check if localStorage is available
    isAvailable: function() {
        try {
            var test = '__storage_test__';
            localStorage.setItem(test, test);
            localStorage.removeItem(test);
            return 1; // Available
        } catch (e) {
            return 0; // Not available
        }
    }
};

// Merge into Emscripten's library
mergeInto(LibraryManager.library, GodotStorage);
