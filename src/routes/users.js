const express = require('express');
const router = express.Router();
const { getAll, getOne, create, remove } = require('../controllers/users');

router.get('/',     getAll);
router.get('/:id',  getOne);
router.post('/',    create);
router.delete('/:id', remove);

module.exports = router;