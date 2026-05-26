const request = require('supertest');
const app = require('../src/app');

describe('GET /health', () => {
  it('should return 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /api/users', () => {
  it('should return a list of users', async () => {
    const res = await request(app).get('/api/users');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('users');
    expect(Array.isArray(res.body.users)).toBe(true);
  });
});

describe('GET /api/users/:id', () => {
  it('should return a single user', async () => {
    const res = await request(app).get('/api/users/1');
    expect(res.statusCode).toBe(200);
    expect(res.body.user).toHaveProperty('id', 1);
  });

  it('should return 404 for unknown user', async () => {
    const res = await request(app).get('/api/users/9999');
    expect(res.statusCode).toBe(404);
  });
});

describe('POST /api/users', () => {
  it('should create a new user', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ name: 'Charlie', email: 'charlie@example.com' });
    expect(res.statusCode).toBe(201);
    expect(res.body.user).toHaveProperty('name', 'Charlie');
  });

  it('should return 400 if name or email missing', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ name: 'NoEmail' });
    expect(res.statusCode).toBe(400);
  });
});

describe('DELETE /api/users/:id', () => {
  it('should delete an existing user', async () => {
    const res = await request(app).delete('/api/users/2');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('User deleted');
  });

  it('should return 404 for unknown user', async () => {
    const res = await request(app).delete('/api/users/9999');
    expect(res.statusCode).toBe(404);
  });
});

describe('GET /unknown-route', () => {
  it('should return 404', async () => {
    const res = await request(app).get('/unknown-route');
    expect(res.statusCode).toBe(404);
  });
});