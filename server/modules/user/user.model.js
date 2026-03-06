const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const User = sequelize.define("Users",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        owner_name: { type: DataTypes.STRING, allowNull: false },
        phone: { type: DataTypes.STRING, allowNull: false, unique: true },
        email: { type: DataTypes.STRING, allowNull: true, unique: true },
        password: { type: DataTypes.STRING, allowNull: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: "true" }
    },
    {
        tableName: "users",
        timestamps: true
    }
);

module.exports = User;
