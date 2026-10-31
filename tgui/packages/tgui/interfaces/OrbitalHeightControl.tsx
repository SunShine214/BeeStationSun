import { useEffect, useRef, useState } from 'react';
import { Button, DraggableClickableControl, Knob } from 'tgui/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type OrbitalData = {
  current_altitude: number;
  station_pos: number[];
  orbital_velocity: number[];
  semi_major_axis: number;
  eccentricity: number;
  arg_of_periapsis: number;
  station_target_angle: number;
  station_actual_angle: number;
  orbital_angle: number;
  orbital_items: OrbitalItem[];
  cinus_radius: number;
  cinus_name: string;
  cinus_grav_mass: number;
  atmosphere_height: number;
  atmosphere_normal: number;
  atmosphere_low: number;
  atmosphere_destruction: number;
};

type OrbitalItem = {
  name: string;
  radius: number;
  pos_x: number;
  pos_y: number;
};

type Simulation = {
  x: number;
  y: number;
  vx: number;
  vy: number;
};

export const OrbitalHeightControl = () => {
  return (
    <Window width={640} height={580}>
      <Window.Content
        style={{
          fontFamily: 'Consolas, "Courier New", monospace',
          background: 'linear-gradient(180deg, #0a0a0a 0%, #1a1a1a 100%)',
        }}
      >
        <OrbitalHeightContent />
      </Window.Content>
    </Window>
  );
};

const OrbitalRing = (props) => {
  const {
    center_x,
    center_y,
    semi_major_axis,
    eccentricity,
    arg_of_periapsis,
    color,
    pixel_scale,
  } = props;
  const display_x = center_x * pixel_scale;
  const display_y = center_y * pixel_scale;
  const display_sma = semi_major_axis * pixel_scale;
  if (semi_major_axis <= 0 || eccentricity < 0 || eccentricity >= 1) {
    return null;
  }
  return (
    <ellipse
      cx={-(display_sma * eccentricity)}
      cy={0}
      rx={display_sma}
      ry={display_sma * Math.sqrt(1 - eccentricity * eccentricity)}
      fill="none"
      stroke={color}
      transform={`translate(${display_x} ${display_y}) rotate(${arg_of_periapsis})`}
    />
  );
};

function OrbitalObjectAnimation(
  origin_pos: number[],
  station_pos: any[],
  station_velo: number[],
  grav_mass: number,
  time_scale: number,
) {
  const sim = useRef({
    x: station_pos[0],
    y: station_pos[1],
    vx: station_velo[0],
    vy: station_velo[1],
  });

  const [position, set_position] = useState(station_pos);

  useEffect(() => {
    sim.current = {
      x: station_pos[0],
      y: station_pos[1],
      vx: station_velo[0],
      vy: station_velo[1],
    };
    set_position(station_pos);
  }, [station_pos[0], station_pos[1], station_velo[0], station_velo[1]]);

  useEffect(() => {
    let last_time = 0;
    let frame_id;
    function animate_object(current_time) {
      if (last_time === 0) last_time = current_time;
      let delta_time = (current_time - last_time) / 1000;
      last_time = current_time;
      sim.current = OrbitalObjectStep(
        origin_pos,
        [sim.current.x, sim.current.y],
        [sim.current.vx, sim.current.vy],
        delta_time * time_scale,
        grav_mass,
      );
      set_position([sim.current.x, sim.current.y]);
      frame_id = requestAnimationFrame(animate_object);
    }

    frame_id = requestAnimationFrame(animate_object);

    return () => {
      cancelAnimationFrame(frame_id);
    };
  }, [
    station_pos[0],
    station_pos[1],
    station_velo[0],
    station_velo[1],
    grav_mass,
  ]);
  return position;
}

function OrbitalObjectStep(
  origin_pos,
  step_pos,
  step_velo,
  delta_time,
  grav_mass,
): Simulation {
  let x = step_pos[0] - origin_pos[0];
  let y = step_pos[1] - origin_pos[1];
  let vx = step_velo[0];
  let vy = step_velo[1];

  let radius_squared = x ** 2 + y ** 2;
  let radius = Math.sqrt(radius_squared);

  if (radius === 0 || grav_mass <= 0) return { x: x, y: y, vx: vx, vy: vy };

  const ax = (-grav_mass * x) / (radius_squared * radius);
  const ay = (-grav_mass * y) / (radius_squared * radius);

  x = x + vx * delta_time + 0.5 * ax * delta_time ** 2;
  y = y + vy * delta_time + 0.5 * ay * delta_time ** 2;

  radius_squared = x ** 2 + y ** 2;
  radius = Math.sqrt(radius_squared);

  if (radius === 0) return { x: x, y: y, vx: vx, vy: vy };

  const next_ax = (-grav_mass * x) / (radius_squared * radius);
  const next_ay = (-grav_mass * y) / (radius_squared * radius);

  vx = vx + 0.5 * (ax + next_ax) * delta_time;
  vy = vy + 0.5 * (ay + next_ay) * delta_time;

  return {
    x: x + origin_pos[0],
    y: y + origin_pos[1],
    vx: vx,
    vy: vy,
  };
}

const OrbitalHeightContent = () => {
  const { act, data } = useBackend<OrbitalData>();
  const {
    station_pos = [0, 0],
    current_altitude = 0,
    orbital_velocity = [0, 0],
    semi_major_axis = 0,
    eccentricity = 0,
    arg_of_periapsis = 0,
    station_target_angle = 0,
    station_actual_angle = 0,
    orbital_angle,
    cinus_radius,
    cinus_grav_mass,
    atmosphere_height,
    atmosphere_normal,
    atmosphere_low,
    atmosphere_destruction,
  } = data;
  const pixel_scale = 1 / 40000;

  const [target_x, set_target_x] = useState(Math.cos(station_target_angle));
  const [target_y, set_target_y] = useState(Math.sin(station_target_angle));
  const sim = OrbitalObjectAnimation(
    [0, 0],
    station_pos,
    orbital_velocity,
    cinus_grav_mass,
    2,
  );
  const [zoom, set_zoom] = useState(1);

  return (
    <>
      <DraggableClickableControl
        value={target_x}
        dragMatrix={[-1, 0]}
        step={1}
        stepPixelSize={1}
        onDrag={(e, value) => {
          set_target_x(value);
        }}
        onClick={(e, value) => {}}
        updateRate={5}
      >
        {(control_x) => (
          <DraggableClickableControl
            value={target_y}
            dragMatrix={[0, -1]}
            step={1}
            stepPixelSize={1}
            onDrag={(e, value) => {
              set_target_y(value);
              act('adjust_angle', {
                angle: (Math.atan2(target_y, target_x) * 180) / Math.PI,
              });
            }}
            onClick={(e, value) => {}}
            updateRate={5}
          >
            {(control_y) => (
              <svg
                onMouseDown={(e) => {
                  control_x.handleDragStart(e);
                  control_y.handleDragStart(e);
                }}
                viewBox="-25 -25 50 50"
                height="100px"
                width="100px"
              >
                <line
                  x1={0}
                  y1={0}
                  x2={0}
                  y2={25}
                  transform={`rotate(${station_target_angle} 0 0)`}
                  stroke="blue"
                />
              </svg>
            )}
          </DraggableClickableControl>
        )}
      </DraggableClickableControl>
      <Button
        mt="-10px"
        content={'orbit keeping'}
        onClick={() => act('toggle_orbit_keeping')}
      />
      <Button
        mt="-10px"
        content={'increase'}
        onClick={() => act('increase_thrust')}
      />
      <Button
        mt="-10px"
        content={'decrease'}
        onClick={() => act('decrease_thrust')}
      />
      Height {current_altitude / 1000}
      <Knob
        size={1.5}
        value={zoom}
        minValue={0.1}
        maxValue={5}
        animated={false}
        step={0.1}
        onChange={(_, v) => set_zoom(v)}
      />
      <svg
        height="300px"
        width="300px"
        viewBox={`${-150 * zoom} ${-150 * zoom} ${300 * zoom} ${300 * zoom}`}
      >
        <g transform="scale(1, -1)">
          <line
            x1={sim[0] * pixel_scale}
            y1={sim[1] * pixel_scale}
            x2={sim[0] * pixel_scale + 25}
            y2={sim[1] * pixel_scale}
            transform={`rotate(${station_actual_angle + orbital_angle} ${sim[0] * pixel_scale} ${sim[1] * pixel_scale})`}
            stroke="red"
          />
          <line
            x1={sim[0] * pixel_scale}
            y1={sim[1] * pixel_scale}
            x2={sim[0] * pixel_scale + 25}
            y2={sim[1] * pixel_scale}
            transform={`rotate(${station_target_angle + orbital_angle} ${sim[0] * pixel_scale} ${sim[1] * pixel_scale})`}
            stroke="blue"
          />
          <OrbitalRing
            center_x={0}
            center_y={0}
            semi_major_axis={semi_major_axis}
            eccentricity={eccentricity}
            arg_of_periapsis={arg_of_periapsis}
            color="#ffffff"
            pixel_scale={pixel_scale}
          />
          <circle
            cx={0}
            cy={0}
            r={atmosphere_height * pixel_scale}
            fill="#3284ff3d"
          />
          <circle
            cx={0}
            cy={0}
            r={atmosphere_normal * pixel_scale}
            fill="#54ff323d"
          />
          <circle
            cx={0}
            cy={0}
            r={atmosphere_low * pixel_scale}
            fill="#ffbe3285"
          />
          <circle
            cx={0}
            cy={0}
            r={atmosphere_destruction * pixel_scale}
            fill="#ff3232c7"
          />
          <circle cx={0} cy={0} r={cinus_radius * pixel_scale} fill="#e93c3c" />
          <rect
            x={sim[0] * pixel_scale - 2}
            y={sim[1] * pixel_scale - 2}
            width={4}
            height={4}
            fill="grey"
          />
        </g>
      </svg>
    </>
  );
};
