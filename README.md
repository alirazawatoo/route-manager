# Route Manager

A Rails prototype that orders jobs by location using a sorting concern and a Google Maps distance service.

```text
job locations -> distance API -> pairwise distances -> ordered route
```

Run `bundle install` and `rails server`, and configure a replacement provider key through local credentials. Do not reuse recorded fixture credentials.

The implementation demonstrates route ordering rather than globally optimal vehicle routing. Provider quotas, failed geocoding, traffic, multiple vehicles, time windows, and large input sets are outside scope.
