# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130830151108) do

  create_table "alarms", force: true do |t|
    t.integer  "metric_id"
    t.integer  "period"
    t.float    "threshold"
    t.string   "relation"
    t.integer  "min_length_sec"
    t.float    "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "beanstalk_fetchers", force: true do |t|
    t.datetime "started_fetch_at"
    t.datetime "completed_fetch_at"
    t.integer  "repeat_frequency_sec"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fetch_count"
  end

  create_table "charts", force: true do |t|
    t.integer  "start_time"
    t.integer  "end_time"
    t.integer  "interval"
    t.string   "x_metric_name"
    t.string   "x_data_type"
    t.string   "y_metric_name"
    t.string   "y_data_type"
    t.integer  "dashboard_id"
    t.integer  "chart_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "target"
    t.string   "color"
    t.string   "size"
    t.string   "chart_type"
    t.float    "x_alarm_min",   default: 0.0
    t.float    "x_alarm_max",   default: 1.0
    t.float    "y_alarm_min",   default: 0.0
    t.float    "y_alarm_max",   default: 1.0
    t.float    "x_axis_min"
    t.float    "x_axis_max"
    t.float    "y_axis_min"
    t.float    "y_axis_max"
  end

  create_table "dashboards", force: true do |t|
    t.string   "name"
    t.integer  "rows"
    t.integer  "cols"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "toggle_chart_forms"
    t.boolean  "toggle_presenter_mode"
    t.boolean  "toggle_alarm_mode"
  end

  create_table "data_fetchers", force: true do |t|
    t.datetime "started_fetch_at"
    t.datetime "completed_fetch_at"
    t.integer  "start_min_ago"
    t.integer  "end_min_ago"
    t.integer  "repeat_frequency_sec"
    t.string   "intervals"
    t.string   "metrics"
    t.string   "periods"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fetch_count"
  end

  create_table "datapoints", force: true do |t|
    t.datetime "timestamp"
    t.float    "value"
    t.integer  "metric_id"
    t.integer  "instance_id"
    t.integer  "loadBalancer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "period"
  end

  add_index "datapoints", ["metric_id"], name: "index_datapoints_on_metric_id", using: :btree
  add_index "datapoints", ["period"], name: "index_datapoints_on_period", using: :btree
  add_index "datapoints", ["timestamp"], name: "index_datapoints_on_timestamp", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "instances", force: true do |t|
    t.string   "zone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "title"
    t.integer  "loadBalancer_id"
    t.datetime "stopped_at"
  end

  create_table "load_balancers", force: true do |t|
    t.string   "zone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "title"
  end

  create_table "metrics", force: true do |t|
    t.string   "metric_name"
    t.string   "namespace"
    t.string   "data_type"
    t.string   "unit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "target"
  end

end
