// In-memory store (replace with a real DB later)
let users = [
    { id: 1, name: 'Alice', email: 'alice@example.com' },
    { id: 2, name: 'Bob',   email: 'bob@example.com'   },
  ];
  let nextId = 3;
  
  const getAll = (req, res) => {
    res.status(200).json({ users });
  };
  
  const getOne = (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.status(200).json({ user });
  };
  
  const create = (req, res) => {
    const { name, email } = req.body;
    if (!name || !email) {
      return res.status(400).json({ error: 'name and email are required' });
    }
    const user = { id: nextId++, name, email };
    users.push(user);
    res.status(201).json({ user });
  };
  
  const remove = (req, res) => {
    const index = users.findIndex(u => u.id === parseInt(req.params.id));
    if (index === -1) return res.status(404).json({ error: 'User not found' });
    users.splice(index, 1);
    res.status(200).json({ message: 'User deleted' });
  };
  
  module.exports = { getAll, getOne, create, remove };