import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
const storageKey='getaway-dev-auth-token';
const modeKey='getaway-dev-remember';
const storage={getItem(key){return sessionStorage.getItem(key)??localStorage.getItem(key)},setItem(key,value){if(sessionStorage.getItem(modeKey)==='session'){localStorage.removeItem(key);sessionStorage.setItem(key,value)}else{sessionStorage.removeItem(key);localStorage.setItem(key,value)}},removeItem(key){sessionStorage.removeItem(key);localStorage.removeItem(key)}};
export function setRememberMe(remember){sessionStorage.setItem(modeKey,remember?'persistent':'session');if(remember){const value=sessionStorage.getItem(storageKey);if(value){localStorage.setItem(storageKey,value);sessionStorage.removeItem(storageKey)}}else{const value=localStorage.getItem(storageKey);if(value){sessionStorage.setItem(storageKey,value);localStorage.removeItem(storageKey)}}}
export const sb=createClient('https://mgehamvbkugwctdcmqcp.supabase.co','sb_publishable_36ZFrrvF0SALg27Pg2RKBA_U59eJTF-',{auth:{storage,storageKey,persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
