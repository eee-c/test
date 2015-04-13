// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:test/src/util/path_handler.dart';
import 'package:test/test.dart';

void main() {
  var handler;
  setUp(() => handler = new PathHandler());

  _handle(request) => new Future.sync(() => handler.handler(request));

  test("returns a 404 for a root URL", () {
    var request = new shelf.Request("GET", Uri.parse("http://localhost/"));
    return _handle(request).then((response) {
      expect(response.statusCode, equals(404));
    });
  });

  test("returns a 404 for an unregistered URL", () {
    var request = new shelf.Request("GET", Uri.parse("http://localhost/foo"));
    return _handle(request).then((response) {
      expect(response.statusCode, equals(404));
    });
  });

  test("runs a handler for an exact URL", () {
    var request = new shelf.Request("GET", Uri.parse("http://localhost/foo"));
    handler.add("foo", expectAsync((request) {
      expect(request.handlerPath, equals('/foo'));
      expect(request.url.path, isEmpty);
      return new shelf.Response.ok("good job!");
    }));

    return _handle(request).then((response) {
      expect(response.statusCode, equals(200));
      expect(response.readAsString(), completion(equals("good job!")));
    });
  });

  test("runs a handler for a suffix", () {
    var request = new shelf.Request(
        "GET", Uri.parse("http://localhost/foo/bar"));
    handler.add("foo", expectAsync((request) {
      expect(request.handlerPath, equals('/foo/'));
      expect(request.url.path, 'bar');
      return new shelf.Response.ok("good job!");
    }));

    return _handle(request).then((response) {
      expect(response.statusCode, equals(200));
      expect(response.readAsString(), completion(equals("good job!")));
    });
  });

  test("runs the longest matching handler", () {
    var request = new shelf.Request(
        "GET", Uri.parse("http://localhost/foo/bar/baz"));

    handler.add("foo", expectAsync((_) {}, count: 0));
    handler.add("foo/bar", expectAsync((request) {
      expect(request.handlerPath, equals('/foo/bar/'));
      expect(request.url.path, 'baz');
      return new shelf.Response.ok("good job!");
    }));
    handler.add("foo/bar/baz/bang", expectAsync((_) {}, count: 0));

    return _handle(request).then((response) {
      expect(response.statusCode, equals(200));
      expect(response.readAsString(), completion(equals("good job!")));
    });
  });
}