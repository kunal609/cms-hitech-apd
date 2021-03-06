const tap = require('tap');
const sinon = require('sinon');

const apdsIndex = require('./index');

tap.test('apds endpoint setup', async endpointTest => {
  const app = {};
  const getEndpoint = sinon.spy();
  const postEndpoint = sinon.spy();
  const putEndpoint = sinon.spy();
  const statusEndpoint = sinon.spy();
  const submittedEndpoint = sinon.spy();
  const versionsEndpoint = sinon.spy();

  apdsIndex(
    app,
    getEndpoint,
    postEndpoint,
    putEndpoint,
    statusEndpoint,
    submittedEndpoint,
    versionsEndpoint
  );

  endpointTest.ok(
    getEndpoint.calledWith(app),
    'apds GET endpoint is setup with the app'
  );
  endpointTest.ok(
    postEndpoint.calledWith(app),
    'apds POST endpoint is setup with the app'
  );
  endpointTest.ok(
    putEndpoint.calledWith(app),
    'apds PUT endpoint is setup with the app'
  );

  endpointTest.ok(
    statusEndpoint.calledWith(app),
    'apds status endpoints are setup with the app'
  );

  endpointTest.ok(
    submittedEndpoint.calledWith(app),
    'submitted apds endpoints are setup with the app'
  );

  endpointTest.ok(
    versionsEndpoint.calledWith(app),
    'apds versions endpoints are setup with the app'
  );
});
