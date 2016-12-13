component output="false" {

  public void function onApplicationStart() {

    // setup the application scope to contain cfrel information
    application.cfrel = {};
    application.cfrel.HASH_ALGORITHM = "SHA-256";

    // create a Java Concurrent object proxies to use for application-level
    // concurrency of application.cfrel and application.cfrel caches
    var concurrentHashMapProxy = CreateObject(
      "java",
      "java.util.concurrent.ConcurrentHashMap"
    );
    var concurrentLinkedQueue = CreateObject(
      "java",
      "java.util.concurrent.ConcurrentLinkedQueue"
    );

    // create caches and cache info structures
    application.cfrel.cache = concurrentHashMapProxy.init();

    for (var cacheName in ["parse", "map", "sql", "signatureHash"]) {
      application.cfrel.cache[cacheName] = concurrentHashMapProxy.init();
      application.cfrel.cacheSizeSamples[cacheName] = concurrentLinkedQueue.init();
    }

    // link some java proxies to application scope for better performance in cfrel
    application.cfrel.javaProxies.concurrentLinkedQueue = concurrentLinkedQueue;
  }

  public void function onRequestStart() {
    application.cfrel.cfcPrefix = "src";
    application.cfrel.metrics = true;
    application.cfrel.HASH_ALGORITHM = "SHA-256";
  }
}
